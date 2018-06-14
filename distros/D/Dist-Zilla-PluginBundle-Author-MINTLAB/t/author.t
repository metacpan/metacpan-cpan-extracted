use strict;
use warnings;
use Test::More;
use Test::Deep;

use Dist::Zilla::PluginBundle::Author::MINTLAB;

test_plugin_attributes();
test_plugin_functions();

sub test_plugin_attributes {

    my $plugin = _plugin_ok();

    my %attributes = (
        server                  => { default => 'gitlab', },
        airplane                => { default => 0 },
        license                 => { default => 'LICENSE' },
        exclude_files           => { default => [] },
        copy_file_from_build    => { default => [], around => [], },
        copy_file_from_release  => { default => [] },
        debug                   => { default => 0 },
        upload_to               => { default => 'cpan' },
        authority               => { default => 'cpan:MINTLAB', },
        fake_release            => { default => 0 },
        changes_version_columns => { default => 10 },
    );

    foreach (sort keys %attributes) {
        my $attr = $plugin->meta->find_attribute_by_name($_);
        ok($attr, "Has an attribute called $_");

        _test_defaults_ok($plugin, $attr, $attributes{$_});
    }

}

sub test_plugin_functions {

    my $plugin = _plugin_ok();
    my @functions = qw(
        configure
        copy_files_from_build
        copy_files_from_release
    );

    foreach (@functions) {
        can_ok($plugin, $_);
    }
}

sub _plugin_ok {
    my (%payload) = @_;

    my $plugin = Dist::Zilla::PluginBundle::Author::MINTLAB->new(
        name    => 'Foo::Bar',
        payload => \%payload,
    );
    isa_ok($plugin, "Dist::Zilla::PluginBundle::Author::MINTLAB");
    return $plugin;
}

sub _test_defaults_ok {
    my ($plugin, $attr, $test) = @_;

    my $value       = $attr->get_value($plugin);
    my $name        = $attr->name;
    my $has_default = exists $test->{default};

    if (defined $value && $has_default) {
        cmp_deeply($attr->get_value($plugin),
            $test->{default}, ".. and default value is correct");
    }
    elsif (defined $value && !$has_default) {
        fail(
            ".. and has a default value but we haven't defined one in the test"
        );
    }
    elsif (!defined $value && $has_default) {
        fail(
            ".. and doesn't have a default value but we have defined one in the test"
        );
    }
    else {
        pass(".. and doesn't have default value");
    }
}

done_testing;
