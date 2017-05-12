use 5.014;
use warnings;

our ($ROUND, $PREC);

#
## GMPq
#
Class::Multimethods::multimethod __sub__ => qw(Math::GMPq Math::GMPq) => sub {
    my ($x, $y) = @_;
    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_sub($r, $x, $y);
    $r;
};

Class::Multimethods::multimethod __sub__ => qw(Math::GMPq Math::GMPz) => sub {
    my ($x, $y) = @_;
    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_sub_z($r, $x, $y);
    $r;
};

Class::Multimethods::multimethod __sub__ => qw(Math::GMPq Math::MPFR) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_sub_q($r, $y, $x, $ROUND);
    Math::MPFR::Rmpfr_neg($r, $r, $ROUND);
    $r;
};

Class::Multimethods::multimethod __sub__ => qw(Math::GMPq Math::MPC) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_set_q($r, $x, $ROUND);
    Math::MPC::Rmpc_sub($r, $r, $y, $ROUND);
    $r;
};

#
## GMPz
#
Class::Multimethods::multimethod __sub__ => qw(Math::GMPz Math::GMPz) => sub {
    my ($x, $y) = @_;
    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_sub($r, $x, $y);
    $r;
};

Class::Multimethods::multimethod __sub__ => qw(Math::GMPz $) => sub {
    my ($x, $y) = @_;
    my $r = Math::GMPz::Rmpz_init_set($x);
    $y < 0
      ? Math::GMPz::Rmpz_add_ui($r, $r, -$y)
      : Math::GMPz::Rmpz_sub_ui($r, $r, $y);
    $r;
};

Class::Multimethods::multimethod __sub__ => qw(Math::GMPz Math::GMPq) => sub {
    my ($x, $y) = @_;
    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_z_sub($r, $x, $y);
    $r;
};

Class::Multimethods::multimethod __sub__ => qw(Math::GMPz Math::MPFR) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_sub_z($r, $y, $x, $ROUND);
    Math::MPFR::Rmpfr_neg($r, $r, $ROUND);
    $r;
};

Class::Multimethods::multimethod __sub__ => qw(Math::GMPz Math::MPC) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_set_z($r, $x, $ROUND);
    Math::MPC::Rmpc_sub($r, $r, $y, $ROUND);
    $r;
};

#
## MPFR
#
Class::Multimethods::multimethod __sub__ => qw(Math::MPFR Math::MPFR) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_sub($r, $x, $y, $ROUND);
    $r;
};

Class::Multimethods::multimethod __sub__ => qw(Math::MPFR $) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    $y < 0
      ? Math::MPFR::Rmpfr_add_ui($r, $x, -$y, $ROUND)
      : Math::MPFR::Rmpfr_sub_ui($r, $x, $y, $ROUND);
    $r;
};

Class::Multimethods::multimethod __sub__ => qw(Math::MPFR Math::GMPq) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_sub_q($r, $x, $y, $ROUND);
    $r;
};

Class::Multimethods::multimethod __sub__ => qw(Math::MPFR Math::GMPz) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_sub_z($r, $x, $y, $ROUND);
    $r;
};

Class::Multimethods::multimethod __sub__ => qw(Math::MPFR Math::MPC) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_set_fr($r, $x, $ROUND);
    Math::MPC::Rmpc_sub($r, $r, $y, $ROUND);
    $r;
};

#
## MPC
#
Class::Multimethods::multimethod __sub__ => qw(Math::MPC Math::MPC) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_sub($r, $x, $y, $ROUND);
    $r;
};

Class::Multimethods::multimethod __sub__ => qw(Math::MPC $) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    $y < 0
      ? Math::MPC::Rmpc_add_ui($r, $x, -$y, $ROUND)
      : Math::MPC::Rmpc_sub_ui($r, $x, $y, $ROUND);
    $r;
};

Class::Multimethods::multimethod __sub__ => qw(Math::MPC Math::MPFR) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_set_fr($r, $y, $ROUND);
    Math::MPC::Rmpc_sub($r, $x, $r, $ROUND);
    $r;
};

Class::Multimethods::multimethod __sub__ => qw(Math::MPC Math::GMPz) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_set_z($r, $y, $ROUND);
    Math::MPC::Rmpc_sub($r, $x, $r, $ROUND);
    $r;
};

Class::Multimethods::multimethod __sub__ => qw(Math::MPC Math::GMPq) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_set_q($r, $y, $ROUND);
    Math::MPC::Rmpc_sub($r, $x, $r, $ROUND);
    $r;
};

1;
