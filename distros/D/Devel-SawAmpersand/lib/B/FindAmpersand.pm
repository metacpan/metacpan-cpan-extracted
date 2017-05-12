package B::FindAmpersand;
BEGIN {
  require Config;
  die "B::FindAmpersand not supported for threaded perl" if $Config::Config{usethreads};
}

use B;
use strict;
use vars qw($VERSION);

$VERSION = "0.04";

my $evil = join "", qw"[ ` & ' ]";

sub compile {
    return sub { B::walkoptree(B::main_root(), "findampersand") }
}

sub B::GVOP::findampersand {
    my($op, $level) = @_;
    $op->gv->findampersand($op);
}

sub B::GV::findampersand {
    my($gv) = @_;
    return unless $gv->NAME =~ /^$evil$/;
    my @report = ($gv->NAME, $gv->FILEGV->SV->PV, $gv->LINE);
    warn sprintf "Found evil variable \$%s in file %s, line %s\n", @report;
}

sub B::OP::findampersand {}
*B::SVOP::findampersand = $] < 5.006 ? sub {} : sub {
    shift->gv->findampersand;
};
sub B::PMOP::findampersand {}
sub B::PVOP::findampersand {}
sub B::COP::findampersand {}
sub B::PV::findampersand {}
sub B::AV::findampersand {}
sub B::IV::findampersand {}
sub B::NV::findampersand {}
sub B::NULL::findampersand {}
sub B::SPECIAL::findampersand {}

1;

__END__

=head1 NAME

B::FindAmpersand - A compiler backend to find variables that set sawampersand

=head1 SYNOPSIS

 perl -MO=FindAmpersand file.pl

=head1 DESCRIPTION

The Devel::SawAmpersand can tell you if Perl has set C<sawampersand>,
but it doesn't tell you where.  Sure, you can grep, but what if you don't
know where to grep?

=head1 AUTHOR

Doug MacEachern

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
