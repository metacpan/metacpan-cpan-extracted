package Encode::IBM::939SOSI;

use strict;
use vars qw($VERSION);
$VERSION = '1.01';

use Encode ();

use base qw(Encode::Encoding);
__PACKAGE__->Define('ibm-939-sosi');

my $base37;
my $base939;

sub decode
{
    my ($obj,$str,$chk) = @_;

    $base37 ||= Encode::find_encoding('cp37');
    $base939 ||= Encode::find_encoding('ibm-939');

    my $out;
    foreach my $chunk (split(/\x0E([^\x0F]*\x0F)/, $str)) {
        if ($chunk =~ /\x0F\z/) {
            chop $chunk;
            $out .= $base939->decode($chunk);
        }
        else {
            $out .= $base37->decode($chunk);
        }
    }
    return $out;
}

sub encode
{
    my ($obj,$str,$chk) = @_;

    $base37 ||= Encode::find_encoding('cp37');
    $base939 ||= Encode::find_encoding('ibm-939');

    if ($str =~ s/^([\x00-\xff]+)//) {
        # english
        my $sub = $1;
        return $base37->encode($sub) . $obj->encode($str, $chk);
    }
    elsif ($str =~ s/^([^\x00-\xff]+)//) {
        # chinese - shift in + shift out
        my $sub = $1;
        return "\x0E".$base939->encode($sub)."\x0F".$obj->encode($str, $chk);
    }
}

1;
__END__


=head1 NAME

Encode::IBM::939SOSI

=cut

=cut
