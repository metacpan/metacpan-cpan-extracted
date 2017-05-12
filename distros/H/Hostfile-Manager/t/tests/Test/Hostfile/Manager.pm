package Test::Hostfile::Manager;

use strict;
use warnings;
use Test::Most;
use Test::NoWarnings qw/had_no_warnings/;
use File::Slurp;
use base 'Test::Class';

sub class { 'Hostfile::Manager'; }

sub startup : Tests(startup => 1) {
    my $test = shift;
    use_ok $test->class;
}

sub constructor : Tests(3) {
    my $test  = shift;
    my $class = $test->class;
    can_ok $class, 'new';
    ok my $manager = $class->new, '... and the constructor should succeed';
    isa_ok $manager, $class, '... and the object it returns';
}

sub path_prefix : Tests(3) {
    my $test    = shift;
    my $manager = $test->class->new;

    my $default_prefix = '/etc/hostfiles/';
    my $new_prefix     = '/etc/hostfiles/2/';

    can_ok $manager,    'path_prefix';
    is $default_prefix, $manager->path_prefix,
      '... and path_prefix should start out with default value';

    $manager->path_prefix($new_prefix);
    is $manager->path_prefix, $new_prefix,
      '... and setting its value should succeed';
}

sub hostfile_path : Tests(3) {
    my $test    = shift;
    my $manager = $test->class->new;

    my $default_hostfile_path = '/etc/hosts';
    my $new_hostfile_path     = '/etc/hosts2';

    can_ok $manager,           'hostfile_path';
    is $default_hostfile_path, $manager->hostfile_path,
      '... and hostfile_path should start out with default value';

    $manager->hostfile_path($new_hostfile_path);
    is $manager->hostfile_path, $new_hostfile_path,
      '... and setting its value should succeed';
}

sub hostfile : Tests(4) {
    my $test = shift;

    my $file    = 't/fixtures/hosts/1';
    my $content = read_file($file);

    my $manager = $test->class->new( hostfile_path => $file );

    can_ok $manager, 'hostfile';
    is $content,     $manager->hostfile,
      '... and hostfile should start out with content of file at hostfile_path';
    throws_ok { $manager->hostfile('foobar') } qr/^Cannot assign a value/,
      '... and settings its value should NOT succeed';
    is $content, $manager->hostfile,
      '... and settings its value did not succeed';
}

sub hostfile_is_lazy : Tests(2) {
    my $test = shift;

    my $file    = 't/fixtures/hosts/1';
    my $content = read_file($file);

    my $manager = $test->class->new( hostfile_path => 'non_existent' );
    $manager->hostfile_path($file);

    can_ok $manager, 'hostfile';
    is $content,     $manager->hostfile,
'... and hostfile should start out with content of file at hostfile_path, even when constructed with a different hostfile_path';
}

sub hostfile_cannot_be_set_in_constructor : Tests(1) {
    my $test = shift;

    my $file    = 't/fixtures/hosts/1';
    my $content = read_file($file);

    my $manager = $test->class->new(
        hostfile_path => $file,
        hostfile      => 'this should be ignored'
    );

    is $content, $manager->hostfile,
      'hostfile should start out with content of file at hostfile_path';
}

sub load_hostfile : Tests(3) {
    my $test    = shift;
    my $manager = $test->class->new;

    my $file    = 't/fixtures/hosts/1';
    my $content = read_file($file);

    can_ok $manager, 'load_hostfile';
    ok $manager->load_hostfile($file),
      '... and load_hostfile indicates success';
    is $content, $manager->hostfile,
      '... and load_hostfile actually loaded the file';
}

sub load_hostfile_uses_hostfile_path : Tests(3) {
    my $test    = shift;
    my $manager = $test->class->new;

    my $file    = 't/fixtures/hosts/1';
    my $content = read_file($file);
    $manager->hostfile_path($file);

    can_ok $manager, 'load_hostfile';
    ok $manager->load_hostfile, '... and load_hostfile indicates success';
    is $content, $manager->hostfile,
      '... and load_hostfile actually loaded the file';
}

sub load_hostfile_requires_hostfile_existence : Tests(2) {
    my $test    = shift;
    my $manager = $test->class->new;

    my $file = 't/fixtures/hosts/non_existent';

    can_ok $manager, 'load_hostfile';
    throws_ok { $manager->load_hostfile($file) } qr/^Hostfile must exist/,
      '... and load_hostfile chokes when hostfile missing';
}

sub get_fragment : Tests(2) {
    my $test = shift;

    my $hostfile = 't/fixtures/hosts/1';
    my $prefix   = 't/fixtures/fragments/';
    my $fragment = 'f1';

    my $manager =
      $test->class->new( path_prefix => $prefix, hostfile_path => $hostfile );

    can_ok $manager, 'get_fragment';
    is read_file( $prefix . $fragment ), $manager->get_fragment($fragment),
      '... and get_fragment returns fragment content';
}

sub get_fragment_returns_undef_when_fragment_missing : Tests(2) {
    my $test = shift;

    my $hostfile = 't/fixtures/hosts/1';
    my $prefix   = 't/fixtures/fragments/';
    my $fragment = 'non_existent';

    my $manager =
      $test->class->new( path_prefix => $prefix, hostfile_path => $hostfile );

    can_ok $manager, 'get_fragment';
    is undef, $manager->get_fragment($fragment),
      '... and get_fragment undef when fragment file missing';
}

sub block : Tests(2) {
    my $test    = shift;
    my $manager = $test->class->new;

    my $fragment_name = 'f1';
    my $block_regexp =
qr/#+\s*BEGIN: $fragment_name[\r\n](.*)#+\s*END: $fragment_name[\r\n]/ms;

    can_ok $manager,  'block';
    is $manager->block($fragment_name), $block_regexp;
}

sub write_hostfile : Tests(3) {
    my $test    = shift;
    my $manager = $test->class->new;

    my $file    = 't/fixtures/hosts/1';
    my $content = read_file($file);

    $manager->load_hostfile($file);

    can_ok $manager, 'write_hostfile';

    my $file2 = 't/fixtures/hosts/write_test';
    unlink($file2);

    $manager->hostfile_path($file2);
    ok $manager->write_hostfile, '... and write_hostfile returns ok';
    is $content, read_file($file2), "... and hostfile written to $file2";

    unlink($file2);
}

sub write_hostfile_requires_writable : Tests(3) {
    my $test    = shift;
    my $manager = $test->class->new;

    my $file    = 't/fixtures/hosts/1';
    my $content = read_file($file);

    $manager->load_hostfile($file);

    can_ok $manager, 'write_hostfile';

    SKIP: {
        skip 'Cannot test writable requirements as root', 2 if ($< == 0);
        my $file2 = 't/fixtures/hosts/write_test';
        write_file( $file2, '' );
        chmod 0444, $file2;

        $manager->hostfile_path($file2);
        throws_ok { $manager->write_hostfile } qr/^Unable to write hostfile/,
            '... and write_hostfile chokes when trying to write to file without permissions';
        is '', read_file($file2), "... and hostfile NOT written to $file2";

        unlink($file2);
    }
}

sub fragment_enabled : Tests(3) {
    my $test = shift;

    my $path   = 't/fixtures/hosts/2';
    my $prefix = 't/fixtures/fragments/';
    my $manager =
      $test->class->new( hostfile_path => $path, path_prefix => $prefix );

    can_ok $manager, 'fragment_enabled';
    ok $manager->fragment_enabled('f1'),
      '... and fragment_enabled returns ok when fragment is indeed enabled';
    ok !$manager->fragment_enabled('f2'),
      '... and fragment_enabled returns not_ok when fragment is not enabled';
}

sub enable_fragment : Tests(3) {
    my $test = shift;

    my $path   = 't/fixtures/hosts/1';
    my $prefix = 't/fixtures/fragments/';
    my $manager =
      $test->class->new( hostfile_path => $path, path_prefix => $prefix );

    can_ok $manager, 'enable_fragment';
    ok $manager->enable_fragment('f1'),
      '... and enable_fragment returns ok when fragment is newly enabled';
    ok $manager->fragment_enabled('f1'), '... and fragment is indeed enabled';
}

sub enable_fragment_does_not_leave_multiple_entries : Tests(4) {
    my $test = shift;

    my $path    = 't/fixtures/hosts/2';
    my $content = read_file($path);
    my $prefix  = 't/fixtures/fragments/';
    my $manager =
      $test->class->new( hostfile_path => $path, path_prefix => $prefix );

    can_ok $manager, 'enable_fragment';
    ok $manager->enable_fragment('f1'),
      '... and enable_fragment returns ok when fragment is newly enabled';
    ok $manager->fragment_enabled('f1'), '... and fragment is indeed enabled';
    is $manager->hostfile, $content, '... and fragment only appears once';
}

sub enable_fragment_does_not_warn_if_fragment_not_loaded : Tests(1) {
    my $test = shift;

    my $path   = 't/fixtures/hosts/2';
    my $prefix = 't/fixtures/fragments/';
    my $manager =
      $test->class->new( hostfile_path => $path, path_prefix => $prefix );

    had_no_warnings $manager->enable_fragment('non_existent'),
'... and enable_fragment does not complain excessively when enabling missing fragment';
}

sub disable_fragment : Tests(4) {
    my $test = shift;

    my $path   = 't/fixtures/hosts/2';
    my $prefix = 't/fixtures/fragments/';
    my $manager =
      $test->class->new( hostfile_path => $path, path_prefix => $prefix );

    can_ok $manager, 'disable_fragment';
    ok $manager->fragment_enabled('f1'),
      '... and fragment_enabled returns ok when fragment is indeed enabled';
    ok $manager->disable_fragment('f1'),
      '... and disable_fragment returns ok when fragment is newly disabled';
    ok !$manager->fragment_enabled('f1'),
      '... and fragment is indeed disabled';
}

sub fragment_list : Tests(2) {
    my $test = shift;

    my $prefix    = 't/fixtures/fragments/';
    my @fragments = ('f1', 'f1a');
    my $manager   = $test->class->new( path_prefix => $prefix );

    can_ok $manager, 'fragment_list';
    is $manager->fragment_list, @fragments,
      '... and fragment list matches expectation';
}

sub toggle_fragment : Tests(6) {
    my $test = shift;

    my $path   = 't/fixtures/hosts/2';
    my $prefix = 't/fixtures/fragments/';
    my $manager =
      $test->class->new( hostfile_path => $path, path_prefix => $prefix );

    can_ok $manager, 'toggle_fragment';
    ok $manager->fragment_enabled('f1'),
      '... and fragment_enabled returns ok when fragment is enabled';
    ok $manager->toggle_fragment('f1'),
      '... and toggle_fragment returns ok when fragment is newly toggled';
    ok !$manager->fragment_enabled('f1'),
      '... and fragment is disabled';
    ok $manager->toggle_fragment('f1'),
      '... and toggle_fragment returns ok when fragment is newly toggled';
    ok $manager->fragment_enabled('f1'),
      '... and fragment is enabled';
}

sub fragment_status_flag : Tests(4) {
    my $test = shift;

    my $path = 't/fixtures/hosts/3';
    my $prefix = 't/fixtures/fragments/';
    my $manager =
      $test->class->new( hostfile_path => $path, path_prefix => $prefix );

    can_ok $manager, 'fragment_status_flag';
    is $manager->fragment_status_flag('f1'), '+',
      '... and fragment_status_flag returns \'+\' when fragment is enabled and unmodified';
    is $manager->fragment_status_flag('f1a'), '*',
      '... and fragment_status_flag returns \'*\' when fragment is enabled and modified';
    is $manager->fragment_status_flag('f2'), ' ',
      '... and fragment_status_flag returns \' \' when fragment is disabled';
}

1;
