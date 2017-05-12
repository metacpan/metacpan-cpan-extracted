package HTML::Template::Compiled::Expression;
use strict;
use warnings;

use constant OPERANDS => 0;
use constant ATTRIBUTES => 1;
use base 'Exporter';
our $VERSION = '1.003'; # VERSION
use  HTML::Template::Compiled::Expression::Expressions;
my @expressions = qw(
    &_expr_literal
    &_expr_defined
    &_expr_ternary
    &_expr_function
    &_expr_method
    &_expr_elsif
);
our @EXPORT_OK = @expressions;
our %EXPORT_TAGS = (
    expressions => \@expressions,
);

sub _expr_literal { HTML::Template::Compiled::Expression::Literal->new(@_) }
sub _expr_defined { HTML::Template::Compiled::Expression::Defined->new(@_) }
sub _expr_ternary { HTML::Template::Compiled::Expression::Ternary->new(@_) }
sub _expr_function { HTML::Template::Compiled::Expression::Function->new(@_) }
sub _expr_method { HTML::Template::Compiled::Expression::Method->new(@_) }
sub _expr_elsif { HTML::Template::Compiled::Expression::Elsif->new(@_) }


sub new {
    my $class = shift;
    my $self = [ [], {} ];
    bless $self, $class;
    $self->init(@_);
    return $self;
}

sub init {}

sub set_operands {
    $_[0]->[OPERANDS] = $_[1];
}

sub get_operands {
    return wantarray
        ? @{ $_[0]->[OPERANDS] }
        : $_[0]->[OPERANDS];
}

sub set_attributes {
    $_[0]->[ATTRIBUTES] = $_[1];
}

sub get_attributes { return $_[0]->[ATTRIBUTES] }

sub to_string { print "$_[0] to_string\n" }

sub level2indent {
    my ($self, $level) = @_;
    no warnings;
    return "  " x $level;
}


package HTML::Template::Compiled::Expression::Conditional;
use base qw(HTML::Template::Compiled::Expression);

sub init {
    my ($self, $op) = @_;
    $self->set_operands([$op]);
}

package HTML::Template::Compiled::Expression::Elsif;
our @ISA = qw(HTML::Template::Compiled::Expression::Conditional);

sub to_string {
    my ($self, $level) = @_;
    my $indent = $self->level2indent($level);
    my ($op) = $self->get_operands;
    return $indent . '}' . $/ . $indent . 'elsif ( ' . $op->to_string . ' ) {';
}

package HTML::Template::Compiled::Expression::SubrefCall;
our @ISA = qw(HTML::Template::Compiled::Expression);

sub init {
    my ($self, @ops) = @_;
    $self->set_operands([@ops]);
}
sub to_string {
    my ($self, $level) = @_;
    my $indent = $self->level2indent($level);
    my ($subref, @ops) = $self->get_operands;
    my @strings = map {
        ref $_ ? $_->to_string($level) : $_
    } @ops;
    return "$indent$subref->( " . (join ',', @strings). ')';
}

package HTML::Template::Compiled::Expression::Function;
our @ISA = qw(HTML::Template::Compiled::Expression);

sub init {
    my ($self, @ops) = @_;
    $self->set_operands([@ops]);
}
sub to_string {
    my ($self, $level) = @_;
    my $indent = $self->level2indent($level);
    my ($function, @ops) = $self->get_operands;
    my @strings = map {
        ref $_ ? $_->to_string($level) : $_
    } @ops;
    return "$indent$function( " . (join ',', @strings). ')';
}

package HTML::Template::Compiled::Expression::Method;
our @ISA = qw(HTML::Template::Compiled::Expression::Function);

sub to_string {
    my ($self, $level) = @_;
    my $indent = $self->level2indent($level);
    my ($function, $object, @args) = $self->get_operands;
    my $start = $indent . (ref $object ? $object->to_string($level) : $object)
        . "->$function( ";
    my @strings = map {
        ref $_ ? $_->to_string($level) : $_
    } @args;
    return $start . (join ',', @strings). ')';
}

1;


__END__

=head1 NAME

HTML::Template::Compiled::Expression - a compiled HTML template expression

=head1 DESCRIPTION

Superclass for all expression types.
