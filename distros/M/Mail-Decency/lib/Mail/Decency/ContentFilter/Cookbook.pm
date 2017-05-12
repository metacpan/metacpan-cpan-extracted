package Mail::Decency::ContentFilter::Cookbook;

use strict;
use warnings;

use version 0.74; our $VERSION = qv( "v0.1.4" );

=head1 NAME

Mail::Decency::ContentFilter::Cookbook - How to write a content filter module

=head1 DESCRIPTION

This module contains a description on howto write a content filter module.

=head1 EXAMPLES

Hope this helps to understand what you can do. Have a look at the existing modules for more examples. Also look at L<Mail::Decency::ContentFilter::Core> for available methods.

=head2 SIMPLE EXAMPLE


    package Mail::Decency::ContentFilter::MyModule;
    
    use Moose;
    extends 'Mail::Decency::ContentFilter::Core';
    
    has some_key => ( is => 'rw', isa => 'Bool', default => 0 );
    
    #
    # The init method is kind of a new or BUILD method, which should
    #   init all configurations from the YAML file
    #
    sub init {
        my ( $self ) = @_;
        
        # in YAML:
        #   ---
        #   some_key: 1
        $self->some_key( 1 )
            if $self->config->{ some_key };
    }
    
    #
    # The handle method will be called by the ContentFilter server each time a new
    #   mail is filtered
    #
    
    sub handle {
        my ( $self ) = @_;
        
        # get the temporary queue file
        my $file = $self->file;
        
        # read the size
        my $size = $self->file_size;
        
        # manipulate the MIME::Entity object of the current
        $self->mime->head->add( 'X-MyModule' => 'passed' );
        $self->write_mime;
        
        # get sender and recipient
        my $sender = $self->from;
        my $recipient = $self->to;
        
        # access the datbaase
        my $data_ref = $self->database->get( schema => table => $search_ref );
        $data_ref->{ some_attrib } = time();
        $self->database->get( schema => table => $search_ref, $data_ref );
        
        # access the cache
        my $cached_ref = $self->cache->get( "cache-name" ) || { something => 1 };
        $cached_ref->{ something } ++;
        $self->cache->set( "cache-name" => $cached_ref );
        
    }

=head2 SPAM FILTER EXAMPLE

    package Mail::Decency::ContentFilter::MySpamFilter;
    
    use Moose;
    extends qw/
        Mail::Decency::ContentFilter::Core::Spam
    /;
    
    
    sub handle {
        my ( $self ) = @_;
        
        # throws exception if spam is recognized
        $self->add_spam_score( -100, "You shall not send me mail" )
            if $self->from eq 'evil@sender.tld';
        
    }

=head2 VIRUS FILTER EXAMPLE

    package Mail::Decency::ContentFilter::MyVirusFilter;
    
    use Moose;
    extends qw/
        Mail::Decency::ContentFilter::Core::Virus
    /;
    
    sub handle {
        my ( $self ) = @_;
        
        # throws exception
        if ( time() % 86400 == 0 ) {
            $self->found_virus( "Your daily virus" );
        }
    }

=head2 HOOKS

There are two kinds of hooks which can be implemented by any modules. They exist, because not necessary all modules will be run in every session (eg if the first recognizes the mail as spam and throws an exception).

=head3 PRE FINISH HOOK

Called after the modules are processed. Has to return the status ("virus", "spam", "drop" or "ok") and the final code (CF_FINAL_* from L<Mail::Decency::ContentFilter::Core::Constants>).

    package Mail::Decency::ContentFilter::MyPreHook;
    
    use Moose;
    extends 'Mail::Decency::ContentFilter::Core';
    use Mail::Decency::ContentFilter::Core::Constants;
    
    # example from the HoneyCollector modules, which
    #   assures marked mails to be collected
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

=head2 POST FINISH HOOK

Called after the finish_(ok|spam|virus) methods. Takes the status as arguments and has to return the status and the final code.

    package Mail::Decency::ContentFilter::MyPreHook;
    
    use Moose;
    extends 'Mail::Decency::ContentFilter::Core';
    use Mail::Decency::ContentFilter::Core::Constants;
    
    sub hook_post_finish {
        my ( $self, $status ) = @_;
        
        # force to pass all recognized virus and spams..
        if ( $status eq 'virus' || $status eq 'spam' ) {
            return ( ok => CF_FINAL_OK );
        }
        
        # delete all mails recognized as OK
        elsif ( $status eq 'ok' ) {
            return ( drop => CF_FINAL_OK );
        }
        
        # bounce mails supposed to be dropped
        elsif ( $status eq 'drop' ) {
            return ( ok => CF_FINAL_ERROR );
        }
    }

=head1 INCLUDE MODULE

To include the module, simple add it in your contnet filter

=head2 YAML

In content-filter.yml ...

    ---
    
    # ..
    
    filters:
        - MyModule:
            some_key: 1
        - MyModule: /path/to/my-module.yml
    

=head2 PERL

    my $content_filter = Mail::Decency::ContentFilter->new(
        # ..
        filters => [
            { MyModule => { some_key => 1 } }
        ]
    );

=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut


1;
