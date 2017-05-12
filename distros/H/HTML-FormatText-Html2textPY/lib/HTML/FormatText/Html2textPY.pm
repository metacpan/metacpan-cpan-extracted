package HTML::FormatText::Html2textPY;

use strict;
use warnings;

use base 'HTML::FormatExternal';

use MRO::Compat;
use mro 'c3';

our $VERSION = '0.13';

use constant DEFAULT_LEFTMARGIN => 0;
use constant DEFAULT_RIGHTMARGIN => 79;
use constant _WIDE_CHARSET => 'iso-8859-1';

=head1 NAME

HTML::FormatText::Html2textPY - format HTML as plain text using html2text python script

=head1 SYNOPSIS

 use HTML::FormatText::Html2textPY;
 $text = HTML::FormatText::Html2textPY->format_file ($filename);
 $text = HTML::FormatText::Html2textPY->format_string ($html_string);

 $formatter = HTML::FormatText::Html2textPY->new;
 $tree = HTML::TreeBuilder->new_from_file ($filename);
 $text = $formatter->format ($tree);

 #if you don't want wrapping do this
 $formatter = HTML::FormatText::Html2textPY->new( rightmargin => -1 );
 $formatter->format_string ($html_string);

=head1 DESCRIPTION

C<HTML::FormatText::Html2textPY> turns HTML into plain text using the
C<html2text> python script. Please make sure you have it installed before 
using this package.

=cut

sub program_full_version {
  my ( $self_or_class ) = @_;
  return $self_or_class->_run_version ( [ 'html2text', '--version' ], '2>&1' );
}

sub program_version {
  my ( $self_or_class ) = @_;
  my $version = $self_or_class->program_full_version;
  if (! defined $version) { return undef; }

  $version =~ /^html2text (.*)/ or $version =~ /^(.*)/;
  return $1;
}

sub _make_run {
  my ( $class, $input_filename, $options ) = @_;
  my @command;

  #turn wrapping off if right margin is set to < 0 in caller
  if ( $class->{rightmargin} < 0 ) {
    @command = ( 'html2text', '--body-width=0' );
  } else {
    @command = ( 'html2text' );
  }

  return ( \@command, '<', $input_filename );
}

=head1 SEE ALSO

L<HTML::FormatExternal>

=head1 AUTHOR

Alex Pavlovic, C<alex.pavlovic@taskforce-1.com>

=head1 COPYRIGHT

Copyright (c) 2013
the HTML::FormatText::Html2textPY L</AUTHOR>
as listed above.

=head1 LICENSE

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
__END__
