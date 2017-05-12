package Email::Store::HTML;
use base "Email::Store::DBI";
use strict;
use Email::Store::Mail;
__PACKAGE__->table("html_body");
__PACKAGE__->columns( All => qw[ id mail raw scrubbed as_text  ] );
__PACKAGE__->columns( Primary => qw/id/);
Email::Store::HTML->has_a(mail => "Email::Store::Mail");
__PACKAGE__->add_constructor(from_mail => 'mail = ?');                      
                                                                                


use HTML::Scrubber;
use HTML::FormatText::WithLinks;        
use vars qw($VERSION @allow @rules @default);

$VERSION = "0.1";


sub on_store_order { 2 }

sub on_store {
    my ($self, $mail) = @_;

    # create the text formatter    
    my $f = HTML::FormatText::WithLinks->new( 
        before_link => '',
        after_link  => ' [ %l ]',
        footnote    => ''
    );


    # create the scrubber
    my $scrubber = HTML::Scrubber->new(
        allow   => \@allow,
        rules   => \@rules,
        default => \@default,
        comment => 1,
        process => 0,
    );




    for ($mail->attachments) {
        next unless $_->content_type eq 'text/html';
        my $raw      =  $_->payload;
        my $scrubbed =  $scrubber->scrub($raw);
        my $text     =  $f->parse($raw); 
        Email::Store::HTML->create( { mail => $mail->id, raw => $raw, scrubbed => $scrubbed, as_text => $text } );
    }
}

=head1 NAME

Email::Store::HTML - various HTML related functions for Email::Store::Mail

=head1 SYNOPSIS

    my $mail = Email::Store::Mail->retrieve( $msgid );
    exit unless $mail->html;

    for ($mail->html) {
        print $_->raw;      # prints out the raw HTML version of the attachment
        print $_->scrubbed; # prints out a scrubbed version of the mail which should be safe
        print $_->as_text;  # prints out a version of the HTML converted to plain text
    }

=head1 DESCRIPTION

=head1 METHODS

=head2 on_store <Email::Store::Mail>

This finds every HTML attachment in the mail and performs various operations on them
before storing them as a new C<Email::Store::HTML> object.

=head2 raw

The raw HTML, exactly as we found it.

=head2 scrubbed

A scrubbed version of the HTML with things like javascript removed.

=head2 as_text

The HTML run through C<HTML::FormatText::WithLinks>. Links are placed after the anchor 
word(a) in square brackets so that

    <a href="http://thegestalt.org">HOME!</a>

becomes

    HOME! [ http://thegestalt.org ]


=head1 BUGS AND TODO

No bugs known at the moment.

It might be nice to give people access to to the scrubber and formatter so that they 
could change the options.

=head1 SUPPORT

This module is part of the Perl Email Project - http://pep.kwiki.org/

There is a mailing list at pep@perl.org (subscribe at pep-subscribe@perl.org)
and an archive available at http://nntp.perl.org/group/pep.php

=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright 2005, Simon Wistow

This code is distributed under the same terms as Perl itself.


=head1 SEE ALSO

L<HTML::Scrubber>, L<HTML::FormatText::WithLinks>

=cut



###
# Configuration for HTML::Scrubber
###

my @allow = qw[ br hr b a p pre ul ol li i em strong table tr td th div ];
                                                                            #
my @rules = (
        script => 0,
        img => {
            border => 1,
            alt => 1,                 # alt attribute allowed
            '*' => 0,                 # deny all other attributes
        },
);
                                                                            #
my @default = (
        0   =>    # default rule, deny all tags
        {
            '*'           => 1, # default rule, allow all attributes
            'href'        => qr{^(?!(?:java)?script)}i,
            'src'         => qr{^(?!(?:java)?script)}i,
            'cite'        => '(?i-xsm:^(?!(?:java)?script))',
            'language'    => 0,
            'name'        => 1, # could be sneaky, but hey ;)
            'onblur'      => 0,
            'onchange'    => 0,
            'onclick'     => 0,
            'ondblclick'  => 0,
            'onerror'     => 0,
            'onfocus'     => 0,
            'onkeydown'   => 0,
            'onkeypress'  => 0,
            'onkeyup'     => 0,
            'onload'      => 0,
            'onmousedown' => 0,
            'onmousemove' => 0,
            'onmouseout'  => 0,
            'onmouseover' => 0,
            'onmouseup'   => 0,
            'onreset'     => 0,
            'onselect'    => 0,
            'onsubmit'    => 0,
            'onunload'    => 0,
            'src'         => 0,
            'type'        => 0,
        }
    );

package Email::Store::Mail;                                                                    
sub html {                                                                       
  my ($self) = @_;                                                              
  return Email::Store::HTML->from_mail($self->message_id);                                           
}       

package Email::Store::HTML;
1;

__DATA__

CREATE TABLE IF NOT EXISTS html_body (
    id integer NOT NULL auto_increment primary key,
    mail         varchar(255) NOT NULL,
    raw          text,
    scrubbed     text,
    as_text      text
);





