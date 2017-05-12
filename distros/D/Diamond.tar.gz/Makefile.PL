use inc::Module::Install;
name 'Diamond';
all_from 'lib/Diamond.pm';
readme_from 'lib/Diamond.pm';

if ($ARGV[0] eq '--regen') {
    warn "regenerating versions.pl\n";
    require 'lib/Diamond.pm';
    require FileHandle;
    open my $out, ">", "versions.pl";
    Diamond->makefile_pl($out);
}

do "versions.pl";

auto_install;
auto_set_repository;
WriteAll;
