#line 1
package Module::Package;

$VERSION = '0.11';

{
    package main;
    use inc::Module::Install;
    pkg;
}

my $target_file = 'inc/Module/Package.pm';
if (-e 'inc/.author' and not -e $target_file) {
    my $source_file = $INC{'Module/Package.pm'}
        or die "Can't bootstrap inc::Module::Package";
    Module::Install::Admin->copy($source_file, $target_file);
}

1;

#line 72
