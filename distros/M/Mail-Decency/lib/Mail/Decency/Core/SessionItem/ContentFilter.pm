package Mail::Decency::Core::SessionItem::ContentFilter;

use Moose;
extends qw/
    Mail::Decency::Core::SessionItem
/;

use version 0.74; our $VERSION = qv( "v0.1.4" );

use MIME::Parser;
use IO::File;
use YAML;
use Data::Dumper;

=head1 NAME

Mail::Decency::Core::SessionItem::ContentFilter

=head1 DESCRIPTION

The id attribute is the current QUEUE ID

=head1 CLASS ATTRIBUTES

=head2 file

The file (in the spool folder, absolute path)

=cut

has file => ( is => 'ro', isa => "Str", required => 1, trigger => \&_init_file );

=head2 store

YAML file containing the current info

=cut

has store => ( is => 'rw', isa => "Str" );

=head2 file_size

Size of the current file (id)

=cut

has file_size => ( is => 'rw', isa => "Int", default => 0 );

=head2 virus

String containg info (name) of the virus

=cut

has virus => ( is => 'rw', isa => "Str" );

=head2 next_id

If set, we now of the next queue id

=cut

has next_id => ( is => 'rw', isa => "Str" );

=head2 prev_id

If set, we now of the previous queue id

=cut

has prev_id => ( is => 'rw', isa => "Str" );

=head2 mime_output_dir

The directory where mime files are to be output (from content filter)

=cut

has mime_output_dir => ( is => 'rw', isa => "Str", required => 1 );

=head2 mime

Is a MIME::Entity object representing the current mail

=cut

has mime => ( is => 'rw', isa => "MIME::Entity" );

=head2 mime_filer

The filer used for cleanup

=cut

has mime_filer => ( is => 'rw', isa => "MIME::Parser::FileUnder" );

=head2 mime_fh

File handle for mime file

=cut

has mime_fh => ( is => 'rw', isa => "IO::File" );

=head2 verify_key

Instance of L<Crypt::OpenSSL::RSA> representing the forward sign key

=cut

has verify_key => ( is => 'rw', isa => 'Crypt::OpenSSL::RSA', predicate => 'can_verify' );


=head2 verify_ttl

TTL for validity of signatures in seconds

=cut

has verify_ttl => ( is => 'rw', isa => 'Int', predicate => 'has_verify_ttl' );


=head2 update_store 

Write store YAML file

=cut

sub update_store {
    my ( $self ) = @_;
    open my $fh, '>', $self->store
        or die "Cannot open store file ". $self->store. " for write: $!";
    my %create = ();
    $create{ from } = $self->from if $self->from;
    $create{ to } = $self->to if $self->to;
    print $fh YAML::Dump( {
        file => $self->file,
        size => $self->file_size,
        %create
    } );
    close $fh;
}


=head2 update_from_policy_cache 

Update session from cached policy session

=cut

sub update_from_policy_cache {
    my ( $self, $hash_ref ) = @_;
    
    # update spam score
    $self->spam_score( $self->spam_score + $hash_ref->{ spam_score } )
        if $hash_ref->{ spam_score };
    
    # update spam details
    push @{ $self->spam_details }, @{ $hash_ref->{ spam_details } }
        if $hash_ref->{ spam_details };
    
    # update spam details
    if ( $hash_ref->{ flags } ) {
        $self->set_flag( $_ ) for keys %{ $hash_ref->{ flags } };
    }
    
    return;
}


=head2 update_from_cache 

Update session from cached session

=cut

sub update_from_cache {
    my ( $self, $hash_ref ) = @_;
    
    $self->update_from_policy_cache( $hash_ref );
    
    $self->virus( join( "; ", $self->virus, $hash_ref->{ virus } ) )
        if $hash_ref->{ virus };
    
    foreach my $id( qw/ next_id prev_id / ) {
        $self->$id( $hash_ref->{ $id } )
            if ! $self->$id && $hash_ref->{ $id };
    }
    
    return;
}


=head2 write_mime 

Update the file ($self->file) from mime .. should be performed after
mime manipulations

=cut

sub write_mime {
    my ( $self ) = @_;
    
    # get mime object
    my $mime = $self->mime;
    
    # resync file size
    $mime->sync_headers( Length => 'COMPUTE' );
    
    # store backup fore failure recovery
    my $tmp_name = $self->file. ".$$.". time();
    rename( $self->file, $tmp_name );
    
    # write back to file
    eval {
        unlink( $self->file );
        open my $fh, '>', $self->file;
        $mime->print( $fh );
        close $fh;
    };
    
    # restore backup on error
    if ( $@ ) {
        rename( $tmp_name, $self->file );
        return 0;
    }
    else {
        unlink( $tmp_name );
    }
    
    return 1;
}


=head2 for_cache

returns data formatted for cache

=cut

sub for_cache {
    my ( $self ) = @_;
    
    return {
        spam_score   => $self->spam_score,
        spam_details => $self->spam_details,
        virus        => $self->virus,
        queue_id     => $self->id,
        next_id      => $self->next_id,
        prev_id      => $self->prev_id
    };
}


=head2 cleanup

Called at the end of the session.. removes all temp files and the mail file

=cut

sub cleanup {
    my ( $self ) = @_;
    
    # close mime handle
    eval { $self->mime_fh->close }; # do silent, don't care
    
    # clear mime
    $self->mime_filer->purge;
    
    # remove store file
    unlink $self->store
        if $self->store && -f $self->store;
    
    # remove store file
    unlink $self->file
        if $self->file && -f $self->file;
    
    $self->unset;
    
    return ;
}


=head2 retreive_policy_scoring

=cut

sub retreive_policy_scoring {
    my ( $self, $accept_scoring ) = @_;
    
    # having decency instance (from policy) ?
    my @instance = map {
        chomp;
        my ( $instance, $signature, $weight, $timestamp, $flags, @info ) = split( /\|/, $_ );
        [ $instance, $signature, $weight, $timestamp, $flags, @info ];
    } $self->mime->head->get( 'X-Decency-Instance' );
    
    # remember wheter cleanup is required
    my $cleanup_instance = scalar @instance > 0;
    
    # using signed forwarded info ? (bother only if scoring from external is accepted!)
    if ( @instance && $accept_scoring && $self->can_verify ) {
        
        # get all valid instances
        @instance = grep {
            my ( $instance, $signature, $weight, $timestamp, $flags, @info ) = @$_;
            
            # verify instance
            my $ok = $self->verify_key->verify(
                join( "|", $signature, $weight, $timestamp, $flags, @info ),
                pack( "H*", $signature )
            );
            
            # valid ?
            $ok && $timestamp <= time() && ( ! $self->has_verify_ttl || $timestamp + $self->verify_ttl >= time() );
        } @instance;
    }
    
    # having any instances ?
    if ( @instance ) {
        
        # handle first instance
        #   this is the LATEST instance.. contains the FINAL score
        my $first_ref = shift @instance;
        my ( $instance, $keyword, $weight, $timestamp, $flags, @info ) = @$first_ref;
        
        # try read from cache
        #   if policy and content filter use the same cache, this will hit!
        my $cached = $self->cache->get( "POLICY-$instance" );
        if ( $cached ) {
            
            # remove policy finally from cache..
            #   there are no policy filters behind the content filter ..
            $self->cache->remove( "POLICY-$instance" );
            
            # add spam score, details
            $self->update_from_policy_cache( $cached );
        }
        
        # not from cache
        #   if policy server accepts scorings in the first place ..
        elsif ( $accept_scoring ) {
            
            # init for update ..
            #   only the first weight will be used, because it is the last
            #   policy weight and therfore the cumulated policy weight
            $cached= {
                spam_score   => $weight,
                spam_details => \@info,
                flags        => { map { ( $_ => 1 ) } split( /\s*,\s*/, $flags ) }
            };
            
            # get flags and info from older instances
            foreach my $older_instance( @instance ) {
                ( undef, undef, undef, undef, my $add_flags, my @add_info )
                    = split( /\|/, $instance );
                push @{ $cached->{ spam_details } }, @add_info;
                $cached->{ flags }->{ $_ } = 1 for split( /\s*,\s*/, $add_flags );
            }
            
            # add spam score, details
            $self->update_from_policy_cache( $cached );
        }
    }
    
    # cleanup instances ?
    if ( $cleanup_instance ) {
        $self->mime->head->delete( 'X-Decency-Instance' );
        $self->write_mime();
    }
}

=pod

PRIVATE METHODS

=pod

_init_file

Triggerd on file set

=cut

sub _init_file {
    my ( $self ) = @_;
    
    die "Cannot access file '". $self->file. "'" unless -f $self->file;
    $self->file_size( -s $self->file );
    
    # store
    $self->store( $self->file. '.info' );
    my $has_store = 0;
    if ( -f $self->store ) {
        $has_store++;
        my $ref;
        eval {
            $ref = YAML::LoadFile( $self->store );
        };
        die "Error loading YAML file ". $self->store. ": $@" if $@;
        die "YAML file ". $self->store. " mal formatted, should be HASH, is '". ref( $ref ). "'"
            unless ref( $ref ) eq 'HASH';
        
        foreach my $attr( qw/ from to / ) {
            $self->$attr( $ref->{ $attr } ) unless $self->$attr;
        }
    }
    
    # setup mime
    my $parser = MIME::Parser->new;
    $parser->output_under( $self->mime_output_dir );
    $parser->decode_headers( 1 );
    
    # read from file and create
    my $orig_fh = IO::File->new( $self->file, 'r' )
        or die "Cannot open ". $self->file. " for read\n";
    
    eval {
        my $mime = $parser->parse( $orig_fh );
        $self->mime( $mime );
        $self->mime_filer( $parser->filer );
        $self->mime_fh( $orig_fh );
    };
    die "Error parsing MIME: $@\n" if $@;
    
    # extract relevant headers ..
    unless ( $self->to ) {
        my $to = "". ( $self->mime->head->get( 'Delivered-To' ) ||  $self->mime->head->get( 'To' )  || "" );
        if ( $to ) {
            if ( $to =~ /<([^>]+)>/ ) {
                $self->to( $1 );
            }
            else {
                $self->to( $to );
            }
        }
    }
    
    # extact from..
    unless ( $self->from ) {
        my $from = "". ( $self->mime->head->get( 'Return-Path' ) ||  $self->mime->head->get( 'From' ) || "" );
        if ( $from ) {
            if ( $from =~ /<([^>]+)>/ ) {
                $self->from( $1 );
            }
            else {
                $self->from( $from );
            }
        }
    }
    
    # write relevant info to store file
    $self->update_store() unless $has_store;
}

=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut

1;
