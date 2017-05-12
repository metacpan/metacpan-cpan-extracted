package Email::AddressParser;

use 5.008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Email::AddressParser ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.04';

require XSLoader;
XSLoader::load('Email::AddressParser', $VERSION);

sub new { 
   bless { personal => $_[1],
           email => $_[2],
           comment => $_[3],
           original => $_[4],
         }, $_[0]; 
}

sub phrase
{
   my $this = shift;

   return $this->{personal};
}

sub original
{
   my $this = shift;

   return $this->format;
}

sub address
{
   my $this = shift;
   return $this->{email};
}

sub format
{
   my $this = shift;
   if($this->{personal}) {
      return _quoted_phrase($this->{personal}) . " <" . $this->{email} . ">";
   } else {
      return $this->{email};
   }
}

sub comment { "" }

sub parse
{
   my $class = shift;
   my $data = shift;
   my $arr = internal_parse($data);
   my @rv = ();

   for my $v (@$arr) {
      bless $v, "Email::AddressParser";
      push @rv, $v;
   }

   return @rv;
}

sub _quoted_phrase {
  my $phrase = shift;

  return $phrase if $phrase =~ /\A=\?.+\?=\z/;

  $phrase =~ s/\A"(.+)"\z/$1/;
  $phrase =~ s/\"/\\"/g;

  return qq{"$phrase"};
}

1;
__END__

=head1 NAME

Email::AddressParser - RFC 2822 Address Parsing and Creation

=head1 SYNOPSIS

  use Email::AddressParser;

  my @addresses = Email::AddressParser->parse($line);
  my $address   = Email::AddressParser->new(Tony => 'tony@localhost');

  print $address->format;

=head1 VERSION

version 0.01

=head1 DESCRIPTION

This class is a near drop-in replacement for the regex parsing of Email::Address, which has serious issues for production use (exponential to infinite computation time in some cases). It uses code from Mark Crispin's c-client library
to implement the parsing. The resulting parser is much more stable than the
regex-based version of Email::Address.

Note, RFC2822 comments are removed by this version (you can pass them in,
and you can ask for them, but they will always be empty).

=head2 Class Methods

=over 4

=item parse

  my @addrs = Email::Address->parse(
    q[me@local, Tony <me@local>, "Tony" <me@local>]
  );

This method returns a list of C<Email::Address> objects it finds
in the input string. 

There are no comment nesting limitations on this method, though all
comments will be ignored.

=item new

  my $address = Email::Address->new(undef, 'tony@local');
  my $address = Email::Address->new('tony kay', 'tony@local');
  my $address = Email::Address->new(undef, 'tony@local', '(tony)');

Constructs and returns a new C<Email::AddressParser> object. Takes four
positional arguments: phrase, email, and comment.

=head2 Instance Methods
    
=over 4
    
=item phrase

  my $phrase = $address->phrase;
  $address->phrase( "Me oh my" );

Accessor for the phrase portion of an address.

=item address
  my $addr = $address->address;
  $addr->address( "me@PROTECTED.com" );

Accessor for the address portion of an address.

=item comment 
  
  my $comment = $address->comment;
  $address->comment( "(Work address)" );

Accessor for the comment portion of an address. Currently a no-op.

=item format

  my $printable = $address->format;

Returns a properly formatted RFC 2822 address representing the
object.

=back

=head1 SEE ALSO

L<Email::Address>.

=head1 AUTHOR

Parser by Mark Crispin. Perl integration by Anthony Kay
<F<tkay@cs.uoregon.edu>>. Most documentation shamelessly borrowed from
L<Email::Address>.

=head1 COPYRIGHT

All parsing code is Copyright (c) 1988-2006 University of Washington, under the
Apache License 2.0. The Perl integration is licesened under the same terms as
Perl itself.

=cut
