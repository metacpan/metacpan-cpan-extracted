package inc::Config::AutoConf::LMU;

use strict;
use warnings;

use Config::AutoConf '0.315';

use base qw(Config::AutoConf);

sub _have_feature_define_name
{
    my $feature   = $_[0];
    my $have_name = "HAVE_FEATURE_" . uc($feature);
    $have_name =~ tr/ /_/;
    $have_name =~ tr/_A-Za-z0-9/_/c;
    $have_name;
}

sub check_statement_expression
{
    my $options = {};
    scalar @_ > 2 and ref $_[-1] eq "HASH" and $options = pop @_;
    my ($self, $header) = @_;
    $self = $self->_get_instance();
    my $feature = "statement expression";

    my $cache_name = $self->_cache_name(qw(feature statement expression));
    my $check_sub  = sub {
        my $prologue = defined $options->{prologue} ? $options->{prologue} : "";
        my $decl = "#define STMT_EXPR ({ 1; })";

        my $have_stmt_expr = $self->compile_if_else(
            $self->lang_build_bool_test($prologue, "STMT_EXPR", $decl),
            {
                ($options->{action_on_true}  ? (action_on_true  => $options->{action_on_true})  : ()),
                ($options->{action_on_false} ? (action_on_false => $options->{action_on_false}) : ())
            }
        );

        $have_stmt_expr;
    };

    # Run the check and cache the results.
    return $self->check_cached(
        $cache_name,
        "for $feature feature",
        $check_sub,
        {
            action_on_true => sub {
                $self->define_var(
                    _have_feature_define_name($feature),
                    $self->cache_val($cache_name),
                    "Defined when feature $feature is available"
                );
                $options->{action_on_cache_true}
                  and ref $options->{action_on_cache_true} eq "CODE"
                  and $options->{action_on_cache_true}->();
            },
            action_on_false => sub {
                $self->define_var(_have_feature_define_name($feature), undef, "Defined when feature $feature is available");
                $options->{action_on_cache_false}
                  and ref $options->{action_on_cache_false} eq "CODE"
                  and $options->{action_on_cache_false}->();
            },
        }
    );
}

sub check_lmu_prerequisites
{
    my $self = shift->_get_instance();

    $self->check_produce_loadable_xs_build() or die "Can't produce loadable XS module";
    $self->check_default_headers();
    $self->check_all_headers(qw(time.h sys/time.h));
    $self->check_funcs([qw(time)]);

    unless ($self->check_types([qw(size_t ssize_t)]))
    {
        $self->check_sizeof_types(
            ["int", "long", "long long", "ptr"],
            {
                prologue => $self->_default_includes
                  . <<EOPTR
typedef void * ptr;
EOPTR
            }
        );
    }
    $self->check_builtin("expect");
    $self->check_statement_expression();
}

1;
