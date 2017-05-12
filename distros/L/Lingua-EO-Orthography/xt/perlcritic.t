use Test::Requires {
    'Perl::Critic'       => 1.094,
    'Test::Perl::Critic' => 0,
};

# Test::Perl::Critic->import(
#     -profile => 'xt/perlcriticrc',
# );
all_critic_ok();

__END__

=pod

=head1 NAME

perlcritic.t - testing that modules complies with Perl::Critic

=cut
