package Dist::Maker::Config;
use Mouse;
use MouseX::StrictConstructor;

use Dist::Maker::Util qw(save);

# data = default config + user's config (from file) + application data

use File::Basename ();
use File::Spec;

with 'Dist::Maker::Logger';

has data => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        my($config) = @_;
        my $data = {
            software => File::Basename::basename($0),
            core => {
                verbose  => 0,
            },
            module => {
                initial_version => '0.01',

            },
            template => {
                default   => 'Default',
                module    => [qw(Time::Piece)],
                dist_init => 1,
            },
            user     => {
                name  => '<<YOUR NAME HERE>>',
                email => '<<YOUR EMAIL ADDRESS HERE>>',
            },
            namespace => [],
        };
        return $config->merge_data($data, $config->user_data);
    },
);

has user_data => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        my($config) = @_;

        my $file = $config->config_file;
        my $new  = do $file || {};
        return $new;
    },
);

has home_dir => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { "$ENV{HOME}/.dim" },
);

has verbose => (
    is      => 'rw',
    isa     => 'Int',
    lazy    => 1,
    default => sub {
        my($self) = @_;
        return $self->data->{core}{verbose};
    },
);

has config_file => (
    is       => 'rw',
    isa      => 'Str',
    lazy     => 1,
    default  => sub {
        my($config) = @_;
        return $config->path('config.pl');
    },
);

has distconfig_file => (
    is       => 'rw',
    isa      => 'Str',
    lazy     => 1,
    default  => sub {
        my($config) = @_;
        return '.dimconfig';
    },
);

sub path {
    my($config, $basename) = @_;
    return File::Spec->catfile(
        $config->home_dir,
        $basename,
    );
}

sub load_class {
    my($config, $parts) = @_;
    my @namespaces;
    if(my $namespace = $config->data->{namespace}) {
        unshift @namespaces, ref($namespace) eq 'ARRAY'
            ? @{$namespace}
            :   $namespace;
    }
    return Mouse::Util::load_first_existing_class(
        map { join '::', $_, $parts }
            @namespaces, 'Dist::Maker');
}

sub read_config_from_file {
    my($config, $file) = @_;
    my $new = do $file || {};
    $config->add_data($new);
    return;
}

sub _merge_array {
    my($base, $new) = @_;
    push @{$base}, ref($new) eq 'ARRAY' ? @{$new} : $new;
    return;
}

sub _merge_hash {
    my($base, $new) = @_;
    while(my($k, $v) = each %{$new}) {
        my $b = $base->{$k};
        if(ref $b eq 'HASH') {
            _merge_hash($b, $v);
        }
        elsif(ref $b eq 'ARRAY') {
            _merge_array($b, $v);
        }
        else {
            $base->{$k} = $v;
        }
    }
    return;
}

sub add_user_data {
    my($config, $data) = @_;
    _merge_hash($config->user_data, $data);
    return;
}

sub add_data {
    my($config, $data) = @_;
    _merge_hash($config->data, $data);
    return;
}

sub merge_data {
    my($self, @data) = @_;
    my %vars;
    foreach my $d(@data) {
        _merge_hash(\%vars, $d);
    }
    return \%vars;
}

sub dump_data {
    my($self, $data) = @_;
    require Data::Dumper;
    my $dd = Data::Dumper->new([$data]);
    $dd->Quotekeys(0);
    $dd->Sortkeys(1);
    $dd->Terse(1);
    $dd->Indent(1);
    return $dd->Dump();
}


sub save_data {
    my($config, $file, $data) = @_;
    $data //= $config->user_data;
    $file //= $config->config_file;

    my $home = $config->home_dir();
    if(not -e $home) {
        mkdir $home       or warn "Cannot mkdir $home: $!";
        chmod 0700, $home or warn "Cannot chmod $home: $!";
    }

    my $header = "#!perl\n" . "# This file is managed by $0.\n";
    $config->save( $file => $header . $config->dump_data($data) )
        or die "Cannot save config file";
    chmod 0600, $file;
}

sub save_data_to_distconfig {
    my($config, $distdir, $data) = @_;

    $config->save_data( "$distdir/" . $config->distconfig_file, $data);
}


no Mouse;
__PACKAGE__->meta->make_immutable();

__END__

=head1 NAME

Dist::Maker::Config - Configuration variables

=head1 VARIABLES

=head2 core.verbose

Logging level.
Default to C<3>.

=head2 user.name

Your name used as the author name.
Available as C<< <: $user.name :> >> in templates.

=head2 user.email

Your email address used as the author's email address.
Available as C<< <: $user.email :> >> in templates.

=head2 template.default

A template name used template by default.
Default to C<Default>.

=head2 template.module

Modules used in templates, i.e. C<< Text::Xslate->new( module => $module ) >>.
Default to C<< ['Time::Piece'] >>.

=head2 template.dist_init

If true (default), C<< dim init >> will does extra things, e.g.
C<< perl Makefile.PL && make manifest >> by the Default template.

=head2 pause.user

PAUSE ID used in C<ship> subcommand (NOT YET IMPLEMENTED).

=head2 pause.password

PAUSE password used in C<ship> subcommand (NOT YET IMPLEMENTED).

=head2 module.initial_version

The initial version of modules.
Default to C<0.01>.

=cut
