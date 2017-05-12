my $var = 1;

$DB::single = 1;

=pod

This is going to be stripped

=cut

eval <<'EOT';
# a comment

$DB::single = 1;

$var = 2; # just some code
EOT

1; # to avoid the program terminating
