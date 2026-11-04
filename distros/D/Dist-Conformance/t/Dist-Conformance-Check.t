#!/usr/bin/env perl
use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Test2::V0;
use Test2::Plugin::NoWarnings;
use FindBin::libs;
use FindBin();
use Mojo::File();
use Module::Runtime();
use Pod::Simple::SimpleTree();

use Fixture();
use Dist::Conformance::Snapshot::Directory();
use Dist::Conformance::Update();
use Dist::Conformance::Check();

package Fake::Check {
    use Mojo::Base 'Dist::Conformance::Check', -signatures;
    sub config_schema ($)          { return { required => ['file'], properties => { file => { type => 'string' }, flag => { type => 'boolean', default => 0 } } } }
    sub check ( $self, $snapshot ) { return $snapshot->contains( $self->config->{file} ) ? ( 'pass', 'there' ) : ( 'fail', 'absent' ) }
}

sub fake (%config) { return Fake::Check->from_config( name => 'Fake', config => \%config, source => Fixture::standards(), variables => { DIST => 'Foo-Bar' } ) }

subtest schema => sub {
    my $schema = Fake::Check->schema;
    is( $schema->{required},                      ['file'],                     'the required keys of the check' );
    is( [ sort keys %{ $schema->{properties} } ], [qw{file flag level module}], 'its keys and the keys of every check' );
    is( $schema->{additionalProperties},          0,                            'and no others' );
    is( Dist::Conformance::Check->config_schema,  { properties => {} },         'the base class takes no keys of its own' );
};

subtest from_config => sub {
    my $check = fake( file => 'x' );
    is( $check->config, { file => 'x', flag => F(), level => 'fail' }, 'the defaults are filled in' );
    is( $check->name,   'Fake',                                        'the name is kept' );
    like( dies { fake() }, qr/\Athe\ check\ Fake\ is\ not\ valid:\n.+\/file:\ Missing/, 'a required key is required, and the check is named' );
    like( dies { fake( file => 'x', typo   => 1 ) },      qr/Properties\ not\ allowed:\ typo/,     'an unknown key is refused' );
    like( dies { fake( file => 'x', level  => 'warn' ) }, qr/\/level:\ Not\ in\ enum\ list/,       'level is fail or info' );
    like( dies { fake( file => 'x', module => 'a b' ) },  qr/\/module:\ String\ does\ not\ match/, 'module is a package name' );
    like(
        dies { Fake::Check->from_config( name => 'Fake', config => {}, where => 'the check Fake of the flavor f' ) },
        qr/\Athe\ check\ Fake\ of\ the\ flavor\ f\ is\ not\ valid/,
        'where names the configuration'
    );
};

subtest check => sub {
    like( dies { Dist::Conformance::Check->new->check( Fixture::checkout() ) }, qr/does\ not\ implement\ check/, 'check is abstract' );
};

subtest update => sub {
    my $failing = Fixture::run_update( fake( file => 'nope' ), Fixture::checkout() );
    is( $failing->manual,                                                                ['absent: Fake has no automatic fix'], 'the default update says that it cannot fix a failure' );
    is( $failing->changes,                                                               [],                                    'and changes nothing' );
    is( Fixture::run_update( fake( file => 'x' ), Fixture::checkout( x => 1 ) )->manual, [],                                    'and says nothing when the check passes' );
};

subtest template => sub {
    my $check = fake( file => 'x' );
    is( [ $check->template('templates/perltidyrc') ], ["-l=400\n-i=4\n"], 'a template without placeholders' );
    my ( $text, @unfilled ) = $check->template('templates/Changes');
    like( $text, qr/\ARevision\ history\ for\ Foo-Bar\n/, 'a variable is filled in' );
    like( $text, qr/\{\{VERSION\}\}\ \{\{DATE\}\}/,       'and a placeholder without one is left' );
    is( \@unfilled, [qw{CPAN_ID DATE VERSION}], 'and named, sorted, once each' );
    like( dies { $check->template('templates/none') }, qr/have\ no\ templates\/none/, 'a missing template is an error' );
};

subtest write_template => sub {
    my $check  = fake( file => 'x' );
    my $root   = Fixture::checkout();
    my $update = Dist::Conformance::Update->new( snapshot => Dist::Conformance::Snapshot::Directory->new( root => $root ) );
    ok( $check->write_template( $update, 'tidy', 'templates/perltidyrc', oct 755 ), 'a template without placeholders is written' );
    is( $root->child('tidy')->slurp,                "-l=400\n-i=4\n", 'with its bytes' );
    is( $root->child('tidy')->stat->mode & oct 777, oct 755,          'and its mode' );
    ok( !$check->write_template( $update, 'Changes', 'templates/Changes' ), 'a template with a placeholder left is not written' );
    ok( !-e $root->child('Changes'),                                        'so there is no file' );
    is( $update->manual, ['Write Changes from templates/Changes by hand, or set the variables CPAN_ID, DATE, VERSION in .conformance.yml: nothing sets them'], 'and a person is told which variables' );
};

subtest missing => sub {
    my $snapshot = Dist::Conformance::Snapshot::Directory->new( root => Fixture::checkout( a => 1, c => 1 ) );
    is( [ fake( file => 'x' )->missing( $snapshot, qw{c b a d} ) ], [qw{b d}], 'the paths that are not there, in their order' );
};

# Every check module that ships: it loads, it is a check, and its POD documents each key that it takes.
subtest 'the shipped checks' => sub {
    my $dir     = Mojo::File->new("$FindBin::Bin/../lib/Dist/Conformance/Check");
    my @modules = map { $_->basename('.pm') } $dir->list->grep(qr/[.]pm\z/)->each;
    ok( scalar @modules >= 8, 'there are the checks of the harness' );
    for my $module (@modules) {
        my $class = Module::Runtime::use_module("Dist::Conformance::Check::$module");
        ok( $class->isa('Dist::Conformance::Check'), "$module is a check" );
        my $pod   = Pod::Simple::SimpleTree->new->parse_file( $dir->child("$module.pm")->to_string )->root;
        my @items = items_of($pod);
        for my $key ( sort keys %{ $class->config_schema->{properties} } ) {
            ok( ( grep { $_ eq $key } @items ), "$module documents its key $key" );
        }
    }
};

# The text of every =item of a POD tree.
sub items_of ($root) {
    my ( @items, @queue );
    @queue = ($root);
    while ( my $node = shift @queue ) {
        next if ref $node ne 'ARRAY';
        my ( $type, undef, @children ) = @$node;
        push @items, join q{}, grep { !ref } @children if $type eq 'item-text';
        push @queue, @children;
    }
    return @items;
}

done_testing;
