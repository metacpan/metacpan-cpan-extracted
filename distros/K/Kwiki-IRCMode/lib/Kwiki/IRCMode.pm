package Kwiki::IRCMode;
our $VERSION = '0.302';

=head1 NAME

Kwiki::IRCMode - colorized IRC conversations in your Kwiki

=head1 VERSION

version 0.302

=head1 SYNOPSIS

 $ cpan Kwiki::IRCMode
 $ cd /path/to/kwiki
 $ kwiki -add Kwiki::IRCMode

=head1 DESCRIPTION

This module registers a ".irc" block, which will format IRC conversations like
the following:

 .irc
 <rjbs> Hey, is there an IRC block for Kwiki?
 <z00s> No.  Why don't you shut up and write one?
 <rjbs> Maybe I will!
 <z00s> Maybe you should!
 <rjbs> FINE!
 .irc

=cut

use strict;
use warnings;
use Kwiki::Plugin '-Base';
use Kwiki::Installer '-Base';

const class_id => 'irc';
const css_file => 'irc.css';
const class_title => 'Kwiki IRC Log Waffle';

sub register {
  my $registry = shift;
  $registry->add(wafl => irc => 'Kwiki::IRCMode::Wafl' );
}

package Kwiki::IRCMode::Wafl;
use base qw(Spoon::Formatter::WaflBlock);

use Parse::IRCLog;
my $p = Parse::IRCLog->new;

=head2 C<< $self->to_html() >>

This converts IRC log messages to HTML.

=cut

sub to_html {
  my (@msgs, %nicks);

  my $html = "<blockquote class='irc'>\n";

  for (split("\n", $self->block_text)) {
    my $event = $p->parse_line($_); $event->{nick_prefix} ||= '';
    defined $nicks{$event->{nick}} or $nicks{$event->{nick}} = scalar keys %nicks;
    $html .= "<p>";
    if (defined $event->{timestamp}) { $html .= "[$event->{timestamp}]"; }
    if ($event->{type} eq 'msg') {
      $html .=
        "&lt;$event->{nick_prefix}<span class='u$nicks{$event->{nick}}'>$event->{nick}</span>&gt; $event->{text}";
    } elsif ($event->{type} eq 'action') {
      $html .=
        " * <span class='u$nicks{$event->{nick}}'>$event->{nick}</span> $event->{text}";
    } else {
      $html .= "$event->{text}";
    }
    $html .= "</p>\n";
  }

  $html .= "</blockquote>\n";

  return $html;
}

=head1 TODO

=head1 AUTHOR

Ricardo SIGNES, <C<rjbs@cpan.org>>

=head1 COPYRIGHT

This code is Copyright 2004, Ricardo SIGNES.  It is licensed under the same
terms as Perl itself.

=cut

package Kwiki::IRCMode;

__DATA__
__css/irc.css__
blockquote.irc {
  background-color: #ddd;
}
blockquote.irc span.u0 { color: #f00; }
blockquote.irc span.u1 { color: #00f; }
blockquote.irc span.u2 { color: #0f0; }
blockquote.irc span.u3 { color: #a0a; }
blockquote.irc p { margin: 0; padding: 0; }
