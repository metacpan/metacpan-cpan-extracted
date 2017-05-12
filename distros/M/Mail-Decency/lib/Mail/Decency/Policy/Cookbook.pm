package Mail::Decency::Policy::Cookbook;

use strict;
use warnings;

use version 0.74; our $VERSION = qv( "v0.1.4" );

=head1 NAME

Mail::Decency::Policy::Cookbook - How to write a policy module

=head1 DESCRIPTION

This module contains a description on howto write a content filter module.

=head1 EXAMPLES

Hope this helps to understand what you can do. Have a look at the existing modules for more examples. Also look at L<Mail::Decency::Policy::Core> for available methods.

=head2 SIMPLE EXAMPLE


    package Mail::Decency::Policy::MyModule;
    
    use Moose;
    extends 'Mail::Decency::Policy::Core';
    
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
        my ( $self, $server, $attrs_ref ) = @_;
        
        # $attrs_ref is:
        #   {
        #       client_address    => '123.123.123.213',
        #       recipient_address => 'recipient@domain.tld',
        #       recipient_domain  => 'domain.tld',
        #       sender_address    => 'sender@domain.tld',
        #       sender_domain     => 'domain.tld',
        #   ...
        #   }
        #   see http://www.postfix.org/SMTPD_POLICY_README.html
        
        # add spam score (throws exception)
        $self->add_spam_score( -300,
            "Message for X-Decency-Detail header",
            "Reject message for SMTP REJECT"
        ) if $attrs_ref->{ client_address } eq '123.123.123.0';
        
        # go to a final state (throws exception)
        $self->go_final_state( OK => "Mail is accepted" )
            if $attrs_ref->{ recipient_domain } eq 'something.tld';
        $self->go_final_state( REJECT => "No, i dont want this" )
            if $attrs_ref->{ recipient_domain } eq 'lalala.tld';
        $self->go_final_state( 454 => "Please, try later" )
            if $attrs_ref->{ recipient_domain } eq 'yadda.tld';
        
        # access the datbaase
        my $data_ref = $self->database->get( schema => table => $search_ref );
        $data_ref->{ some_attrib } = time();
        $self->database->get( schema => table => $search_ref, $data_ref );
        
        # access the cache
        my $cached_ref = $self->cache->get( "cache-name" ) || { something => 1 };
        $cached_ref->{ something } ++;
        $self->cache->set( "cache-name" => $cached_ref );
        
        # set a flag for later evaluation (also in ContentFilter)
        $self->set_flag( 'bla' );
        $self->logger->info( "What can i say?" ) if $self->has_flag( "blub" );
        $self->del_flag( 'nada' ) if time() % 9999 = 33;
        
        # access session data
        warn "> CURRENT SPAM SCORE ". $self->session_data->spam_score. "\n";
    }

=head1 INCLUDE MODULE

To include the module, simple add it in your contnet filter

=head2 YAML

In policy.yml ...

    ---
    
    # ..
    
    policy:
        - MyModule:
            some_key: 1
        - MyModule: /path/to/my-module.yml
    

=head2 PERL

    my $policy = Mail::Decency::Policy->new(
        # ..
        policy => [
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
