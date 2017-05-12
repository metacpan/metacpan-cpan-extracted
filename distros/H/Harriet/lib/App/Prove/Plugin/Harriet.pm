package App::Prove::Plugin::Harriet;
use strict;
use warnings;
use utf8;
use Harriet;

sub load {
    my ($class, $p) = @_;
    my @args = @{ $p->{args} };
    my $dir = shift @args || 't/harriet/';
    my $harriet = Harriet->new($dir);
    $harriet->load_all();
}

1;
__END__

=for stopwords harriet

=head1 NAME

App::Prove::Plugin::Harriet - Harriet with prove

=head1 SYNOPSIS

    # in your .proverc
    -PHarriet=t/harriet/

=head1 DESCRIPTION

This module is a part of L<Harriet>.

This module loads harriet scripts before running tests. And it set environment variables.

Please look L<Harriet> for more details.
