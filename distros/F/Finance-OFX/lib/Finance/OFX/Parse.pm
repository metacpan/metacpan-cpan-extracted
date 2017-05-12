# Filename: Parse.pm
# Parse the Open Financial Exchange format
# http://www.ofx.net/
# 
# Created January 30, 2008	Brandon Fosdick <bfoz@bfoz.net>
#
# Copyright 2008 Brandon Fosdick <bfoz@bfoz.net> (BSD License)
#
# $Id: Parse.pm,v 1.2 2008/03/04 04:22:27 bfoz Exp $

package Finance::OFX::Parse;

use strict;
use warnings;

our $VERSION = '2';

use Finance::OFX::Tree;
use HTTP::Date;

sub is_unique
{
    my $a = shift;
    return undef unless ref($a) eq 'ARRAY';
    my %saw;
    $saw{$_->{name}}++ || return 0 for @{$a};
    1;
}

sub collapse
{
    my $tree = shift;
    return $tree unless ref($tree) eq 'ARRAY';

    # Recurse on any elements that have arrays for content
    $_->{content} = collapse($_->{content}) for( @{$tree} );

    # The passed array can be converted to a hash if all of it's nodes have 
    #  unique names
    my %a;
    if( is_unique($tree) )
    {
	$a{$_->{name}} = $_->{content} for ( @{$tree} );
    }
    else	# Duplicate names can be converted to an array
    {
	my %b;
	$b{$_->{name}}++ for @{$tree};
#	grep(!$b{$_->{name}}++, @{$tree});
	($b{$_} > 1) && ($a{$_} = []) for keys %b;
	for( @{$tree} )
	{
	    push(@{$a{$_->{name}}}, $_->{content}), next if $b{$_->{name}} > 1;
	    $a{$_->{name}} = $_->{content};
#	    ($b{$_->{name}} > 1) ? push(@{$a{$_->{name}}}, $_->{content}) :
#				   ($a{$_->{name}} = $_->{content});
	}
    }
    return \%a;
}

sub parse_dates
{
    my $tree = shift;

    if( ref($tree) eq 'ARRAY' )
    {
	parse_dates($_) for @{$tree};
    }
    elsif( ref($tree) eq 'HASH' )
    {
	for( keys %{$tree} )
	{
	    if( /^dt/ )
	    {
		# Add seconds spacer
		$tree->{$_} =~ s/^([0-9]{12})([0-9]{2})/$1:$2/;
		# Add minutes spacer
		$tree->{$_} =~ s/^([0-9]{10})([0-9]{2})/$1:$2/;
		# Add date spacers
		$tree->{$_} =~ s/^([0-9]{4})([0-9]{2})([0-9]{2})/$1-$2\-$3 /;
		# Add a leading zero to the timezone offset, if needed
		$tree->{$_} =~ s/\[([-+]?)([0-9]):[A-Z]{3}\]/ $1\x30$2\x30\x30/;
		# Handle timezone offsets that were already 2 digits
		$tree->{$_} =~ s/\[([-+]?)([0-9]{1,2}):[A-Z]{3}\]/ $1$2\x30\x30/;
		# Do the conversion
		$tree->{$_} = str2time($tree->{$_}, 'GMT');
	    }
	    else
	    {
		parse_dates($tree->{$_});
	    }
	}
    }
}

sub parse
{
    $_[0] =~ s/\x0D//g;			# Un-networkify newlines

    my ($header, $body) = split /\n\n/, shift, 2;

    # Parse the OFX header block
    $header =~ s/^\s//;				# Strip leading whitespace
    my %header = split /[:\n]/, $header;	# Convert to a hash

    return undef unless ($header{OFXHEADER} == '100') and ($header{DATA} eq 'OFXSGML');

    my $tree = Finance::OFX::Tree::parse($body);
    return undef unless $tree and ($tree->[0]{name} eq 'ofx');

    $tree = collapse($tree);		# Collapse the parse tree into a hash
    parse_dates($tree);			# Convert date elements to Unix time

    # Merge the header hash into the parse tree
    $tree->{header} = \%header;

    return $tree;
}

sub parse_file
{
    my $file = shift;
    return undef unless $file;
#    my $text = do { local(@ARGV, $/) = $file; <> };
    my $text = read_file($file);
    return undef unless $text;
    return parse($text);
}

1;

__END__

=head1 NAME

Finance::OFX::Parse - Parse the Open Financial Exchange protocol

=head1 SYNOPSIS

 use Finance::OFX::Parse
 my $tree = Finance::OFX::Parse::parse($ofxContent);

=head1 DESCRIPTION

C<Finance::OFX::Parse> provides two functions, C<parse()> and C<parse_file()>, that 
accept an OFX "file" and return a reference to a hash tree representing the 
contents of the file. C<parse()> expects the OFX content as a scalar argument 
while C<parse_file> expects a filename.

Parsing well-formed OFX content returns a hash with two keys: 'ofx' and 
'header'. The 'ofx' key is a reference to a hash tree representing the <OFX> block 
and the 'header' key is a reference to a hash of header attributes. All date 
values are automatically converted to UNIX time.

=head2 EXAMPLE

If C<$ofxContent> in the above code is...

 OFXHEADER:100
 DATA:OFXSGML
 VERSION:102
 SECURITY:NONE
 ENCODING:USASCII
 CHARSET:1252
 COMPRESSION:NONE
 OLDFILEUID:NONE
 NEWFILEUID:NONE

 <OFX>
    <SIGNONMSGSRSV1>
 	<SONRS>
 	    <STATUS>
 		<CODE>0
 		<SEVERITY>INFO
 		<MESSAGE>SonRq is successful
 	    </STATUS>
 	    <DTSERVER>20080220142819.321[-8:PST]
 	    <LANGUAGE>ENG
 	    <FI>
 		<ORG>DI
 		<FID>074014187
 	    </FI>
 	</SONRS>
    </SIGNONMSGSRSV1>
 </OFX>

...the resulting HoH will be...

 $VAR1 = {
   'ofx' => {
     'signonmsgsrsv1' => {
       'sonrs' => {
         'fi' => {
           'org' => 'DI',
           'fid' => '074014187'
         },
         'language' => 'ENG',
         'status' => {
           'severity' => 'INFO',
           'message' => 'SonRq is successful',
           'code' => '0'
         },
         'dtserver' => '1203546499.321'
       }
     }
   },
   'header' => {
     'CHARSET' => '1252',
     'OFXHEADER' => 100,
     'OLDFILEUID' => 'NONE',
     'COMPRESSION' => 'NONE',
     'SECURITY' => 'NONE',
     'ENCODING' => 'USASCII',
     'NEWFILEUID' => 'NONE',
     'DATA' => 'OFXSGML',
     'VERSION' => '102'
   }
 };

=head1 FUNCTIONS

=over

=item $tree = parse($ofx)

C<parse()> accepts a single scalar argument containing the OFX data to be 
parsed and retunrs a reference to a hash tree.

=item $tree = parse_file($file_name)

C<parse_file()> accepts a single scalar argument containing the path to a file
containing the OFX data to be parsed and retunrs a reference to a hash tree.

=back

=head1 SEE ALSO

L<HTML::Parser>
L<http://ofx.net>

=head1 WARNING

From C<Finance::Bank::LloydsTSB>:

This is code for B<online banking>, and that means B<your money>, and
that means B<BE CAREFUL>. You are encouraged, nay, expected, to audit
the source of this module yourself to reassure yourself that I am not
doing anything untoward with your banking data. This software is useful
to me, but is provided under B<NO GUARANTEE>, explicit or implied.

=head1 AUTHOR

Brandon Fosdick, E<lt>bfoz@bfoz.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Brandon Fosdick <bfoz@bfoz.net>

This software is provided under the terms of the BSD License.

=cut
