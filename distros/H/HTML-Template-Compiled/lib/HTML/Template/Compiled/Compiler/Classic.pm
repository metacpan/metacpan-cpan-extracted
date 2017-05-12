package HTML::Template::Compiled::Compiler::Classic;
use strict;
use warnings;
our $VERSION = '1.003'; # VERSION

use base 'HTML::Template::Compiled::Compiler';

sub parse_var {
    my ( $self, $t, %args ) = @_;
    my $context = $args{context};
    if (!$t->validate_var($args{var})) {
        $t->get_parser->_error_wrong_tag_syntax(
            {
                fname => $context->get_file,
                line  => $context->get_line,
                token => "",
            },
            $args{var}
        );
    }
    my %loop_context = (
        __index__   => '$__ix__',
        __counter__ => '$__ix__+1',
        __first__   => '$__ix__ == $[',
        __last__    => '$__ix__ == $__size__',
        __odd__     => '!($__ix__ & 1)',
        __even__    => '($__ix__ & 1)',
        __inner__   => '$__ix__ != $[ && $__ix__ != $__size__',
        __outer__   => '$__ix__ == $[ || $__ix__ == $__size__',
        __break__   => '$__break__',
        __filename__ => '$t->get_file',
        __filenameshort__ => '$t->get_filename',
        __wrapped__ => '$args->{wrapped}',
    );

    if ( $t->get_loop_context && $args{var} =~ m/^__(\w+)__$/ ) {
        my $lc = $loop_context{ lc $args{var} };
        return $lc;
    }
    my $var = $t->get_case_sensitive ? $args{var} : lc $args{var};
    if ($t->get_global_vars & 1) {
        my $varstr =
            "\$t->_get_var_global_sub(" . '$P,$$C,0,'."[undef,'$var'])";
        return $varstr;
    }
    else {
        $var =~ s/\\/\\\\/g;
        $var =~ s/'/\\'/g;
        my $varstr = '$$C->{' . "'$var'" . '}';
        my $string = <<"EOM";
do { my \$var = $varstr;
  \$var = (ref \$var eq 'CODE') ?  \$var->() : \$var;
EOM
        if ($context->get_name !~ m/^(?:LOOP|WITH)$/) {
            $string .= <<"EOM";
(ref \$var eq 'ARRAY' ? \@\$var : \$var)
EOM
 }
            $string .= '}';
        return $string;
    }
}


1;

__END__

=head1 NAME

HTML::Template::Compiled::Compiler::Classic - Provide the classic functionality like HTML::Template

=head1 DESCRIPTION

This is the compiler class for L<HTML::Template::Compiled::Classic>

=head1 METHODS

=over 4

=item parse_var

Make a path out of tmpl_var name="foobar"

=back

=cut

