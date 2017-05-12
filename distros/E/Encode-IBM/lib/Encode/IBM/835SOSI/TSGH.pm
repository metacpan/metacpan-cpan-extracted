package Encode::IBM::835SOSI::TSGH;

use strict;
use vars qw($VERSION);
$VERSION = '1.01';

use Encode ();

use base qw(Encode::Encoding);
__PACKAGE__->Define('ibm-835-sosi-tsgh');

my $base37;
my $base835;

sub decode
{
    my ($obj,$str,$chk) = @_;

    $base37 ||= Encode::find_encoding('cp37');
    $base835 ||= Encode::find_encoding('ibm-835');
    #$str =~ s/\x00/K/g;
    $str =~ s/\x00/\x40/g;
    $str =~ s/\x30\xe1/Fg/g;    # MAKE SMALL
    $str =~ s/\x30\xe0//g;      # MAKE LARGE
    #$str =~ s/\x30\xe0/Mh/g;

    my $out;
    foreach my $chunk (split(/\x28([^\x29]*\x29)/, $str)) {
        if ($chunk =~ /\x29\z/) {
            chop $chunk;
            $chunk =~ s/\@\@/iJ/g;
            $out .= $base835->decode($chunk);
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
    $base835 ||= Encode::find_encoding('ibm-835');

    if ($str =~ s/^([\x00-\xff]+)//) {
        # english
        my $sub = $1;
        return $base37->encode($sub) . $obj->encode($str, $chk);
    }
    elsif ($str =~ s/^([^\x00-\xff]+)//) {
        # chinese - shift in + shift out
        my $sub = $1;
        return "\x28".$base835->encode($sub)."\x29".$obj->encode($str, $chk);
    }
}

1;
__END__


=head1 NAME

Encode::IBM::835SOSI::TSGH

=cut
