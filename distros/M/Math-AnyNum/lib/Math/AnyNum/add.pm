use 5.014;
use warnings;

our ($ROUND, $PREC);

#
## GMPq
#
Class::Multimethods::multimethod __add__ => qw(Math::GMPq Math::GMPq) => sub {
    my ($x, $y) = @_;
    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_add($r, $x, $y);
    $r;
};

Class::Multimethods::multimethod __add__ => qw(Math::GMPq Math::GMPz) => sub {
    my ($x, $y) = @_;
    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_add_z($r, $x, $y);
    $r;
};

Class::Multimethods::multimethod __add__ => qw(Math::GMPq Math::MPFR) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_add_q($r, $y, $x, $ROUND);
    $r;
};

Class::Multimethods::multimethod __add__ => qw(Math::GMPq Math::MPC) => sub {
    my ($x, $y) = @_;
    my $c = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_set_q($c, $x, $ROUND);
    Math::MPC::Rmpc_add($c, $c, $y, $ROUND);
    $c;
};

#
## GMPz
#
Class::Multimethods::multimethod __add__ => qw(Math::GMPz Math::GMPz) => sub {
    my ($x, $y) = @_;
    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_add($r, $x, $y);
    $r;
};

Class::Multimethods::multimethod __add__ => qw(Math::GMPz $) => sub {
    my ($x, $y) = @_;
    my $r = Math::GMPz::Rmpz_init_set($x);
    $y < 0
      ? Math::GMPz::Rmpz_sub_ui($r, $r, -$y)
      : Math::GMPz::Rmpz_add_ui($r, $r, $y);
    $r;
};

Class::Multimethods::multimethod __add__ => qw(Math::GMPz Math::GMPq) => sub {
    my ($x, $y) = @_;
    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_add_z($r, $y, $x);
    $r;
};

Class::Multimethods::multimethod __add__ => qw(Math::GMPz Math::MPFR) => sub {
    my ($x, $y) = @_;
    my $f = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_add_z($f, $y, $x, $ROUND);
    $f;
};

Class::Multimethods::multimethod __add__ => qw(Math::GMPz Math::MPC) => sub {
    my ($x, $y) = @_;
    my $c = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_set_z($c, $x, $ROUND);
    Math::MPC::Rmpc_add($c, $c, $y, $ROUND);
    $c;
};

#
## MPFR
#
Class::Multimethods::multimethod __add__ => qw(Math::MPFR Math::MPFR) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_add($r, $x, $y, $ROUND);
    $r;
};

Class::Multimethods::multimethod __add__ => qw(Math::MPFR $) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    $y < 0
      ? Math::MPFR::Rmpfr_sub_ui($r, $x, -$y, $ROUND)
      : Math::MPFR::Rmpfr_add_ui($r, $x, $y, $ROUND);
    $r;
};

Class::Multimethods::multimethod __add__ => qw(Math::MPFR Math::GMPq) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_add_q($r, $x, $y, $ROUND);
    $r;
};

Class::Multimethods::multimethod __add__ => qw(Math::MPFR Math::GMPz) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_add_z($r, $x, $y, $ROUND);
    $r;
};

Class::Multimethods::multimethod __add__ => qw(Math::MPFR Math::MPC) => sub {
    my ($x, $y) = @_;
    my $c = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_add_fr($c, $y, $x, $ROUND);
    $c;
};

#
## MPC
#
Class::Multimethods::multimethod __add__ => qw(Math::MPC Math::MPC) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_add($r, $x, $y, $ROUND);
    $r;
};

Class::Multimethods::multimethod __add__ => qw(Math::MPC $) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    $y < 0
      ? Math::MPC::Rmpc_sub_ui($r, $x, -$y, $ROUND)
      : Math::MPC::Rmpc_add_ui($r, $x, $y, $ROUND);
    $r;
};

Class::Multimethods::multimethod __add__ => qw(Math::MPC Math::MPFR) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_add_fr($r, $x, $y, $ROUND);
    $r;
};

Class::Multimethods::multimethod __add__ => qw(Math::MPC Math::GMPz) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_set_z($r, $y, $ROUND);
    Math::MPC::Rmpc_add($r, $r, $x, $ROUND);
    $r;
};

Class::Multimethods::multimethod __add__ => qw(Math::MPC Math::GMPq) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_set_q($r, $y, $ROUND);
    Math::MPC::Rmpc_add($r, $r, $x, $ROUND);
    $r;
};

1;
