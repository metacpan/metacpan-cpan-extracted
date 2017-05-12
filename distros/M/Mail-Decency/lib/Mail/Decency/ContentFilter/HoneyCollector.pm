package Mail::Decency::ContentFilter::HoneyCollector;

use Moose;
extends qw/
    Mail::Decency::ContentFilter::Archive
/;

use version 0.74; our $VERSION = qv( "v0.1.4" );

use mro 'c3';
use Data::Dumper;
use File::Path qw/ make_path /;
use File::Copy qw/ copy /;
use Mail::Decency::Core::Exception;
use Mail::Decency::ContentFilter::Core::Constants;

=head1 NAME

Mail::Decency::ContentFilter::HoneyCollector

=head1 DESCRIPTION

Counter part of the policy server's L<Mail::Decency::Policy::HoneyPot>. It receives honey-flagged mails and either trains them directly into activated spam filters or stores them in a quarantine folder for later manual training.

All mails marked with the honey flag will be dropped and NOT delivered !

=head1 CONFIG

    ---
    
    disable: 0
    #max_size: 0
    #timeout: 30
    
    # train into activated spam filters
    #train: 0
    
    # directory for collecting spams mails
    archive_dir: /var/spool/decency/honey
    

=head1 CLASS ATTRIBUTES


=head2 archive_dir : Str

Output directory of honey mails. The format is the same as for the L<Mail::Decency::ContentFilter::Archive> module.

=cut

has archive_dir => ( is => 'rw', isa => 'Str', predicate => 'do_collect' );

=head2 train : Bool

Wheter train tagged mails into activated spam filters 

=cut

has train => ( is => 'rw', isa => 'Bool', default => 0 );


=head1 METHODS


=head2 init

=cut

sub init {
    my ( $self ) = @_;
    
    # init base, assure we get mime encoded
    $self->next::method();
    
    # enable collection
    if ( $self->config->{ archive_dir } ) {
        make_path( $self->config->{ archive_dir }, { mode => 0700 } )
            unless -d $self->config->{ archive_dir };
        die "HoneyCollector: Could not create archive_dir '". $self->config->{ archive_dir }. "'\n"
            unless -d $self->config->{ archive_dir };
        $self->archive_dir( $self->config->{ archive_dir } );
    }
    
    # enable train
    $self->train( 1 )
        if $self->config->{ train };
    
    # min required
    die "HoneyCollector: Activate at least one of train or archive_dir\n"
        unless $self->train || $self->do_collect;
    
    $self->logger->debug0( "Train spam mails: ". ( $self->train ? "enabled" : "disabled" ) );
    $self->logger->debug0( "Collect spam mails: ". ( $self->do_collect ? "enabled" : "disabled" ) );
    
}


=head2 handle

Archive file into archive folder

=cut


sub handle {
    my ( $self ) = @_;
    
    # only act on marked mails
    return
        if ! $self->session_data->has_flag( 'honey' )
        || $self->session_data->has_flag( 'honey_collected' )
    ;
    
    # set honey collected
    $self->session_data->set_flag( 'honey_collected' );
    
    # collect the honey
    $self->_collect_honey();
    
    # drop mail in any case
    Mail::Decency::Core::Exception::Drop->throw( { message => "Drop after collection" } );
}


=head2 hook_pre_finish

If no honey has been collected (cause some spam filters ran before) -> get it now

=cut

sub hook_pre_finish {
    my ( $self, $status ) = @_;
    
    # has been flagged..
    return ( $status, CF_FINAL_OK )
        if ! $self->session_data->has_flag( 'honey' )
        || $self->session_data->has_flag( 'honey_collected' )
    ;
    
    # collect the honey
    $self->_collect_honey();
    
    # drop the mail
    return ( 'drop', CF_FINAL_OK );
}



=head2 _collect_honey

Train to spam filters and / or write to archive directory

=cut

sub _collect_honey {
    my ( $self ) = @_;
    
    # train mail
    if ( $self->train ) {
        $self->logger->debug2( "Train mail into spam" );
        my @spam_modules = 
            grep {
                $_->isa( 'Mail::Decency::ContentFilter::Core::Spam' )
                && $_->isa( 'Mail::Decency::ContentFilter::Core::Cmd' )
                && $_->can_learn_spam
                && ! $_->config->{ disable_train } 
            }
            @{ $self->server->childs }
        ;
        foreach my $module( @spam_modules ) {
            # train into filter
            $module->cmd_filter( 'learn_spam' );
        }
    }
    
    # collect mail.. 
    if ( $self->do_collect ) {
        $self->logger->debug2( "Do collect mail" );
        
        # disable dropping (we'll do ourself)
        $self->drop( 0 );
        
        # perform archive (Mail::Decency::ContentFilter::Archive)
        $self->archive_mail();
    }
    
    return ;
}


=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut


1;
