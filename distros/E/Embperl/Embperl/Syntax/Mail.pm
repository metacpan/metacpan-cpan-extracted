
###################################################################################
#
#   Embperl - Copyright (c) 1997-2008 Gerald Richter / ecos gmbh  www.ecos.de
#   Embperl - Copyright (c) 2008-2014 Gerald Richter
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#   THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
#   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#   WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
#   $Id: Mail.pm 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################
 
package Embperl::Syntax::Mail ;

use Embperl::Syntax qw{:types} ;
use Embperl::Syntax::HTML ;

use strict ;
use vars qw{@ISA} ;

@ISA = qw(Embperl::Syntax::HTML) ;


###################################################################################
#
#   Methods
#
###################################################################################

# ---------------------------------------------------------------------------------
#
#   Create new Syntax Object
#
# ---------------------------------------------------------------------------------


sub new

    {
    my $class = shift ;

    my $self = Embperl::Syntax::HTML::new ($class) ;

    if (!$self -> {-mailInit})
        {
        $self -> {-mailInit} = 1 ;    
        Init ($self) ;
        }

    return $self ;
    }



###################################################################################
#
#   Definitions for Mail HTML tags
#
###################################################################################

sub Init

    {
    my ($self) = @_ ;

    $self -> AddTagBlock ('mail:send', ['from', 'to', 'cc', 'bcc', 'subject', 'reply-to', 
                                        'mailhost', 'mailhelo', 'maildebug', 'content-type'], 
                                        undef, undef, 
                { 
                removenode  =>  106,
		compiletimeperlcode => q{
			$_ep_mail_opt_save = $Embperl::req->component->config->options ;
			$Embperl::req->component->config->options (Embperl::Constant::optKeepSpaces | $_ep_mail_opt_save) ;
			},
		compiletimeperlcodeend => q{
			$Embperl::req->component->config->options ($_ep_mail_opt_save) ;
			},

                perlcodeend =>  q{
                    {
                    use Embperl::Mail ;

                    my $txt = XML::Embperl::DOM::Node::iChildsText (%$n%) ;
                    my @errors ;
                    $? = Embperl::Mail::Execute (
                        {
                        'input'       => \$txt,
                        'inputfile'   => 'mail',
                        'errors'      => \@errors,
                        'syntax'      => 'Text',
                        'from'        => %&'from%,
                        'to'          => %&'to%,
                        'cc'          => %&'cc%,
                        'bcc'         => %&'bcc%,
                        'subject'     => %&'subject%,
                        'reply-to'    => %&'reply-to%,
                        'mailhost'    => %&'mailhost%,
                        'mailhelo'    => %&'mailhelo%,
                        'maildebug'   => %&'maildebug%,
                        'mailheaders' => [ (( %&'content-type% ) ? ('Content-Type: '.%&'content-type%) : ()) ],
                        }) ;
                    print STDERR join ('; ', @errors) if (@errors) ;
                    }
                  },
                stackname   => 'mail_send',
                'push'        => '%$x%',
                },
                ) ;

    }


###################################################################################
#
#   Mail Implementation
#
###################################################################################


1; 

__END__

=pod

=head1 NAME

Embperl::Syntax::Mail - tag library for sending mail

=head1 SYNOPSIS

  [$ syntax + Mail $]

  <mail:send to="richter@ecos.de" subject="Testmail">
    Hi,
    this is a test for a new mail tag
    it is send at [+ scalar(localtime) +]
    from Embperl's Mail taglib.
  </mail:send>

  [$ if $? $]
    <h2>Sorry, there was an error, your mail couldn't be send</h2>
  [$else$]
    <h2>Your mail was successfully delivered</h2>
  [$endif$]


=head1 DESCRIPTION

The is module provides a mail:send tag, for sending text via email. It uses the
Embperl::Mail module for actualy sending the mail. The following attributes
are recognized. The mail body is enclosed between the mail:send tags.
See L<Embperl::Mail> for an description of the attribues:


=over 4

=item from       

=item to         

=item cc         

=item bcc        

=item subject    

=item reply-to   

=item mailhost   

=item mailhelo   

=item maildebug  

=item content-type

=back


On success it sets C<$?> to zero, otherwise to a value other then zero.

=head1 Author

Gerald Richter <richter at embperl dot org>

=head1 See Also

Embperl::Syntax, Embperl::Syntax::HTML

