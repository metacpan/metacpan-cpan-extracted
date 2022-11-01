package Finance::MIFIR::CONCAT;
use 5.014;
use warnings;
use strict;

our $VERSION = '0.01';

use Date::Utility;
use Exporter 'import';
use File::ShareDir;
use YAML::XS qw/LoadFile/;
use utf8;
our @EXPORT_OK = qw(mifir_concat);

=head1 NAME

Finance::MIFIR::CONCAT - provides CONCAT code generation out of client data according to MIFIR rules

=head1 SYNOPSIS

    use Finance::MIFIR::CONCAT qw/mifir_concat/;

    print mifir_concat({
        cc          => 'DE',
        date        => '1960-01-01',
        first_name  => 'Jack',
        last_name   => 'Daniels',
    });

=head1 DESCRIPTION

=cut

=head2 mifir_concat

 Accepts hashref of person's data with keys: cc, date, first_name, last_name.

 Returns string representing CONCATed MIFIR ID.

=cut

our $config       = LoadFile(File::ShareDir::dist_file('Finance-MIFIR-CONCAT', 'mifir.yml'));
our $romanization = LoadFile(File::ShareDir::dist_file('Finance-MIFIR-CONCAT', 'romanization.yml'));

sub mifir_concat {
    my $args = shift;
    my $cc   = $args->{cc};
    my $date = Date::Utility->new($args->{date})->date_yyyymmdd;
    $date =~ s/\-//g;
    my $first_name = _process_name($args->{first_name});
    my $last_name  = _process_name($args->{last_name});
    return uc($cc . $date . $first_name . $last_name);
}

sub _process_name {
    my ($str) = @_;
    $str = lc($str);
    my $strip_re = join "|", (@{$config->{titles}}, @{$config->{prefixes}});
    $strip_re = qr/($strip_re)\s+/;
    $str =~ s/$strip_re//g;
    my $re = join '', keys %$romanization;
    $re = qr/([$re])/;
    $str =~ s/$re/$romanization->{$1}/ge;
    $str =~ s/[^a-z]//g;
    $str = substr($str . '######', 0, 5);
    return $str;
}

1;
