use strict;
use 5.010;

package FusqlFS::Formatter::Html;
use parent 'FusqlFS::Formatter::Base';
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;

=head1 NAME

FusqlFS::Formatter::Html - HTML formatter class

=head1 DESCRIPTION

This formatter outputs data as lists (ordered C<E<lt>olE<gt>> lists for arrays
and definition C<E<lt>dlE<gt>> lists for hashes).

This is a dump-only formatter, it doesn't parse data back into Perl structures,
so you can't edit and save data while using this formatter.

See also L<FusqlFS::Formatter::Htmltable> formatter for data formatted in HTML
tables.

=begin testing

#!noinst

my $hvalue = { a => 1, b => 2, c => 3 };
my $avalue = [ 1, 2, 3 ];
my $svalue = "123";
is {_tpkg}::_Dump($hvalue), q{<dl><dt>a</dt><dd>1</dd><dt>b</dt><dd>2</dd><dt>c</dt><dd>3</dd></dl>}, "hash dumped correctly";
is {_tpkg}::_Dump($avalue), q{<ol><li>1</li><li>2</li><li>3</li></ol>}, "array dumped correctly";
is {_tpkg}::_Dump($svalue), "123", "scalar dumped correctly";

my $complex = { a => 1, b => [2, 3, 4], c => [5] };
is {_tpkg}::_Dump($complex), q{<dl><dt>a</dt><dd>1</dd><dt>b</dt><dd><ol><li>2</li><li>3</li><li>4</li></ol></dd><dt>c</dt><dd><ol><li>5</li></ol></dd></dl>}, "complex structure dumped correctly";

=end testing

=cut

sub Dump
{
    '<html><head><meta charset="utf-8" /><title>FusqlFS data</title><link href="http://netdna.bootstrapcdn.com/twitter-bootstrap/2.2.2/css/bootstrap.no-icons.min.css" rel="stylesheet"></head><body>' . &_Dump . '</body></html>';
}

sub _Dump
{
    my $value = shift;
    my $ref = ref $value;
    return $value unless $ref;

    given ($ref) {
        when ('ARRAY') {
            return '<ol><li>' . join('</li><li>', map _Dump($_), @$value) . '</li></ol>';
        }
        when ('HASH') {
            return '<dl>' . join('', map "<dt>$_</dt><dd>${\_Dump($value->{$_})}</dd>", sort keys %$value) . '</dl>';
        }
        when ('SCALAR') {
            return $$value;
        }
        default {
            return $value;
        }
    }
}

1;
