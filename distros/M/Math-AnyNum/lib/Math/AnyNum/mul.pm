use 5.014;
use warnings;

our ($ROUND, $PREC);

#
## GMPq
#
Class::Multimethods::multimethod __mul__ => qw(Math::GMPq Math::GMPq) => sub {
    my ($x, $y) = @_;
    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_mul($r, $x, $y);
    $r;
};

Class::Multimethods::multimethod __mul__ => qw(Math::GMPq Math::GMPz) => sub {
    my ($x, $y) = @_;
    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_mul_z($r, $x, $y);
    $r;
};

Class::Multimethods::multimethod __mul__ => qw(Math::GMPq Math::MPFR) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_mul_q($r, $y, $x, $ROUND);
    $r;
};

Class::Multimethods::multimethod __mul__ => qw(Math::GMPq Math::MPC) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_set_q($r, $x, $ROUND);
    Math::MPC::Rmpc_mul($r, $r, $y, $ROUND);
    $r;
};

#
## GMPz
#
Class::Multimethods::multimethod __mul__ => qw(Math::GMPz Math::GMPz) => sub {
    my ($x, $y) = @_;
    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_mul($r, $x, $y);
    $r;
};

Class::Multimethods::multimethod __mul__ => qw(Math::GMPz $) => sub {
    my ($x, $y) = @_;
    my $r = Math::GMPz::Rmpz_init();
    $y < 0
      ? Math::GMPz::Rmpz_mul_si($r, $x, $y)
      : Math::GMPz::Rmpz_mul_ui($r, $x, $y);
    $r;
};

Class::Multimethods::multimethod __mul__ => qw(Math::GMPz Math::GMPq) => sub {
    my ($x, $y) = @_;
    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_mul_z($r, $y, $x);
    $r;
};

Class::Multimethods::multimethod __mul__ => qw(Math::GMPz Math::MPFR) => sub {
    my ($x, $y) = @_;
    my $f = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_mul_z($f, $y, $x, $ROUND);
    $f;
};

Class::Multimethods::multimethod __mul__ => qw(Math::GMPz Math::MPC) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_set_z($r, $x, $ROUND);
    Math::MPC::Rmpc_mul($r, $r, $y, $ROUND);
    $r;
};

#
## MPFR
#
Class::Multimethods::multimethod __mul__ => qw(Math::MPFR Math::MPFR) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_mul($r, $x, $y, $ROUND);
    $r;
};

Class::Multimethods::multimethod __mul__ => qw(Math::MPFR $) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    $y < 0
      ? Math::MPFR::Rmpfr_mul_si($r, $x, $y, $ROUND)
      : Math::MPFR::Rmpfr_mul_ui($r, $x, $y, $ROUND);
    $r;
};

Class::Multimethods::multimethod __mul__ => qw(Math::MPFR Math::GMPq) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_mul_q($r, $x, $y, $ROUND);
    $r;
};

Class::Multimethods::multimethod __mul__ => qw(Math::MPFR Math::GMPz) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_mul_z($r, $x, $y, $ROUND);
    $r;
};

Class::Multimethods::multimethod __mul__ => qw(Math::MPFR Math::MPC) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_mul_fr($r, $y, $x, $ROUND);
    $r;
};

#
## MPC
#
Class::Multimethods::multimethod __mul__ => qw(Math::MPC Math::MPC) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_mul($r, $x, $y, $ROUND);
    $r;
};

Class::Multimethods::multimethod __mul__ => qw(Math::MPC $) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    $y < 0
      ? Math::MPC::Rmpc_mul_si($r, $x, $y, $ROUND)
      : Math::MPC::Rmpc_mul_ui($r, $x, $y, $ROUND);
    $r;
};

Class::Multimethods::multimethod __mul__ => qw(Math::MPC Math::MPFR) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_mul_fr($r, $x, $y, $ROUND);
    $r;
};

Class::Multimethods::multimethod __mul__ => qw(Math::MPC Math::GMPz) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_set_z($r, $y, $ROUND);
    Math::MPC::Rmpc_mul($r, $r, $x, $ROUND);
    $r;
};

Class::Multimethods::multimethod __mul__ => qw(Math::MPC Math::GMPq) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_set_q($r, $y, $ROUND);
    Math::MPC::Rmpc_mul($r, $r, $x, $ROUND);
    $r;
};

1;
