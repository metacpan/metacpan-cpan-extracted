use 5.006;
use strict;
use warnings;

=head1 NAME

EJS::Template::Test - Testing utility for EJS::Template

=cut

package EJS::Template::Test;
use base 'Exporter';

use Carp qw(croak);
use EJS::Template;
use Test::Builder;
use Test::More;

our @EXPORT = qw(ejs_test ejs_test_parse);

=head1 Methods

=head2 ejs_test

=cut

sub ejs_test {
    my ($source, $expected, $variables, $config) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    
    my $ejs = EJS::Template->new(%{$config || {}});
    my $prefix = '';
    
    for my $name (qw(engine escape)) {
        if ($ejs->{$name}) {
            $prefix .= $ejs->{$name}.': ';
        }
    }
    
    $prefix ||= 'source: ';
    
    my $output;
    
    eval {
        $ejs->process(\$source, $variables, \$output) or croak $@;
    };
    
    if ($@) {
        fail $prefix."[$source]: $@";
    } else {
        is($output, $expected, $prefix."[$source]");
    }
}

=head2 ejs_test_parse

=cut

sub ejs_test_parse {
    my ($source, $expected) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    
    my $prefix = 'source: ';
    my $output;
    
    eval {
        EJS::Template->parse(\$source, \$output) or croak $@;
    };
    
    if ($@) {
        fail $prefix."[$source]: $@";
    } else {
        is($output, $expected, $prefix."[$source]");
    }
}

=head1 SEE ALSO

=over 4

=item * L<EJS::Template>

=back

=cut

1;
