use YAML;

my $hash = { '/foo/foo- hate' => 'bz' };
print YAML::Dump ($hash);
print YAML::Dump (YAML::Load (YAML::Dump ($hash)));
