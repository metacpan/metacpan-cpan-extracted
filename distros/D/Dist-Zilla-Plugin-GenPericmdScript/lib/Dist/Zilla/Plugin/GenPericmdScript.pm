package Dist::Zilla::Plugin::GenPericmdScript;

our $DATE = '2017-07-07'; # DATE
our $VERSION = '0.41'; # VERSION

use 5.010001;
use strict;
use warnings;

use Moose;
with (
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [':InstallModules'],
    },
    'Dist::Zilla::Role::FileGatherer',
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::PERLANCAR::WriteModules',
);

use namespace::autoclean;

use Perinci::CmdLine::Gen qw(gen_pericmd_script);
use Module::Load;

has build_load_modules => (is=>'rw');

has url => (is=>'rw', required=>1);
has subcommands => (is=>'rw');
has subcommands_from_package_functions => (is=>'rw');
has include_package_functions_match => (is=>'rw');
has exclude_package_functions_match => (is=>'rw');
has name => (is=>'rw');
has summary => (is=>'rw');
has cmdline => (is=>'rw');
has prefer_lite => (is=>'rw');
has enable_log => (is=>'rw');
has pass_cmdline_object => (is=>'rw');
has default_log_level => (is=>'rw');
has extra_urls_for_version => (is=>'rw');
has config_filename => (is=>'rw');
has config_dirs => (is=>'rw');
has ssl_verify_hostname => (is=>'rw');
has load_modules => (is=>'rw');
has code_before_instantiate_cmdline => (is=>'rw');
has code_after_end => (is=>'rw');
has default_format => (is=>'rw');
has skip_format => (is=>'rw');
has use_utf8 => (is=>'rw');
has use_cleanser => (is=>'rw');
has default_dry_run => (is=>'rw');
has allow_prereq => (is=>'rw');
has per_arg_json => (is=>'rw');
has per_arg_yaml => (is=>'rw');
has validate_args => (is=>'rw');
has pack_deps => (is=>'rw');

has inline_generate_completer => (is=>'rw', default=>1);

sub mvp_multivalue_args { qw(build_load_modules load_modules code_before_instantiate_cmdline code_after_end config_filename config_dirs allow_prereq) }

sub gather_files {
    # we actually don't generate scripts in this phase but in the later stage
    # (FileMunger) to be able to get more built version of modules. we become
    # FileGatherer plugin too to get add_file().
}

# XXX extract list_own_modules, is_own_module to its own role/dist
sub is_own_module {
    use experimental 'smartmatch';

    my ($self, $mod) = @_;

    state $own_modules = do {
        my @list;
        for my $file (@{ $self->found_files }) {
            my $name = $file->name;
            next unless $name =~ s!^lib[/\\]!!;
            $name =~ s![/\\]!::!g;
            $name =~ s/\.(pm|pod)$//;
            push @list, $name;
        }
        \@list;
    };

    $mod ~~ @$own_modules ? 1:0;
}

sub munge_files {
    my ($self, $arg) = @_;

    # i do it this way (unshift @INC, "lib" + require "Foo/Bar.pm" instead of
    # unshift @INC, "." + require "lib/Foo/Bar.pm") in my all other Dist::Zilla
    # and Pod::Weaver plugin, so they can work together (require "Foo/Bar.pm"
    # and require "lib/Foo/Bar.pm" would cause Perl to load the same file twice
    # and generate redefine warnings).
    local @INC = ("lib", @INC);

    require Dist::Zilla::File::InMemory;

    my $scriptname = $self->name;
    if (!$scriptname) {
        $scriptname = $self->url;
        if ($scriptname =~ m!([^/]+)/\z!) {
            $scriptname = $1;
        } else {
            $scriptname =~ s!.+/!!;
        }
        $scriptname =~ s/[^A-Za-z0-9]+/-/g;
        $scriptname =~ s/^-//;
        $scriptname = "script" if length($scriptname) == 0;
    }

    my $subcommands;
    if ($self->subcommands) {
        $subcommands = {split /\s*=\s*|\s+/, $self->subcommands};
    }

    my $res;
    {
        # if we use Perinci::CmdLine::Inline, the script might include module(s)
        # from the current dist and we need the built version, not the source
        # version
        $self->write_modules_to_dir;
        my $mods_tempdir = $self->written_modules_dir;

        local @INC = ($mods_tempdir, @INC);

        for (@{ $self->build_load_modules // []}) {
            load $_;
        }

        my $code_before_instantiate_cmdline = $self->code_before_instantiate_cmdline;
        if (ref($code_before_instantiate_cmdline) eq 'ARRAY') { $code_before_instantiate_cmdline = join("\n", @$code_before_instantiate_cmdline) }
        my $code_after_end = $self->code_after_end;
        if (ref($code_after_end) eq 'ARRAY') { $code_after_end = join("\n", @$code_after_end) }

        my %gen_args = (
            url => $self->url,
            script_name => $scriptname,
            script_version => $self->zilla->version,
            script_summary => $self->summary,
            interpreter_path => 'perl',
            (load_module => $self->load_modules) x !!$self->load_modules,
            log => $self->enable_log,
            ($self->extra_urls_for_version ? (extra_urls_for_version => [split(/\s*,\s*/, $self->extra_urls_for_version)]) : ()),
            default_log_level => $self->default_log_level,
            pass_cmdline_object => $self->pass_cmdline_object,
            (cmdline => $self->cmdline) x !!defined($self->cmdline),
            prefer_lite => $self->prefer_lite,
            ssl_verify_hostname => $self->ssl_verify_hostname,
            code_before_instantiate_cmdline => $code_before_instantiate_cmdline,
            code_after_end => $code_after_end,
            (config_filename => $self->config_filename) x !!$self->config_filename,
            (config_dirs => $self->config_dirs) x !!$self->config_dirs,
            (subcommands => $subcommands) x !!$subcommands,
            subcommands_from_package_functions => $self->subcommands_from_package_functions,
            (include_package_functions_match => $self->include_package_functions_match) x !!$self->include_package_functions_match,
            (exclude_package_functions_match => $self->exclude_package_functions_match) x !!$self->exclude_package_functions_match,
            (default_format => $self->default_format) x !!$self->default_format,
            skip_format => $self->skip_format ? 1:0,
            use_utf8 => $self->use_utf8,
            (use_cleanser => $self->use_cleanser) x !!(defined $self->use_cleanser),
            (default_dry_run => $self->default_dry_run) x !!defined($self->default_dry_run),
            (allow_prereq => $self->allow_prereq) x !!$self->allow_prereq,
            (per_arg_json => $self->per_arg_json) x !!defined($self->per_arg_json),
            (per_arg_yaml => $self->per_arg_yaml) x !!defined($self->per_arg_yaml),
            (validate_args => $self->validate_args) x !!defined($self->validate_args),
            (pack_deps => $self->pack_deps) x !!defined($self->pack_deps),
            pod => 0, # will be generated by PWP:Rinci
        );
        #use DD; dd \%gen_args;
        $res = gen_pericmd_script(%gen_args);
        $self->log_fatal("Failed generating $scriptname: $res->[0] - $res->[1]")
            unless $res->[0] == 200;
    }

    {
        my $ver = 0;
        my %mem;
        my $perimod = $res->[3]{'func.cmdline_module'};
        $self->log_debug(["Adding prereq to cmdline module %s", $perimod]);
        $self->zilla->register_prereqs(
            {phase => $res->[3]{'func.cmdline_module_inlined'} ?
                 'develop' : 'runtime'},
            $perimod => $res->[3]{'func.cmdline_module_version'});
        $mem{$perimod}++;

        my $extramods = $res->[3]{'func.extra_modules'} // {};
        for my $extramod (sort keys %$extramods) {
            $self->log_debug(["Adding prereq to extra module %s", $extramod]);
            $self->zilla->register_prereqs(
                 {phase => 'runtime'},
                 $extramod => $extramods->{$extramod});
            $mem{$extramod}++;
        }

        my @urls = ($self->url);
        if ($subcommands && keys %$subcommands) {
            for my $sc_name (sort keys %$subcommands) {
                push @urls, $subcommands->{$sc_name};
            }
        }
        # add prereq to script backend modules
        for my $url (@urls) {
            my ($pkg) = $url =~ m!^(?:pm:)?/(.+)/.*!;
            next unless $pkg;
            $pkg =~ s!/!::!g;
            next if $self->is_own_module($pkg);
            next if $mem{$pkg}++;
            $self->log_debug(["Adding prereq to %s", $pkg]);
            $self->zilla->register_prereqs({phase => 'runtime'}, $pkg => 0);
        }
    }

    my $fileobj = Dist::Zilla::File::InMemory->new(
        name => "script/$scriptname", content => $res->[2]);
    $self->log(["Creating script 'script/%s' from Riap function '%s'", $scriptname, $self->url]);
    $self->add_file($fileobj);

    # create a separate completion script if we use Perinci::CmdLine::Inline,
    # because Perinci::CmdLine::Inline currently does not support completion
    # natively.
    if ($res->[3]{'func.cmdline_module_inlined'} && $self->inline_generate_completer) {
        require App::GenPericmdCompleterScript;
        my $compres = App::GenPericmdCompleterScript::gen_pericmd_completer_script(
            url => $self->url,
            subcommands => $subcommands,
            #default_format => $self->default_format,
            skip_format => $self->skip_format,
            program_name => $scriptname,
            (load_module => $self->load_modules) x !!$self->load_modules,
            read_config => 0,
            read_env => 0,
        );
        $self->log_fatal("Failed generating completer script _$scriptname: $compres->[0] - $compres->[1]")
            unless $compres->[0] == 200;
        my $compfileobj = Dist::Zilla::File::InMemory->new(
            name => "script/_$scriptname", content => $compres->[2]);
        $self->log(["Creating completer script 'script/_%s' from Riap function '%s'", $scriptname, $self->url]);
        $self->add_file($compfileobj);
    }
}


__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Generate Perinci::CmdLine script

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::GenPericmdScript - Generate Perinci::CmdLine script

=head1 VERSION

This document describes version 0.41 of Dist::Zilla::Plugin::GenPericmdScript (from Perl distribution Dist-Zilla-Plugin-GenPericmdScript), released on 2017-07-07.

=head1 SYNOPSIS

In F<dist.ini>:

 ; generate a script, by default called script/check-palindrome
 [GenPericmdScript]
 url=/My/Palindrome/check_palindrome

 ; generate another script, called script/lssrv
 [GenPericmdScript / Gen_lssrv]
 url=/My/App/list_servers
 name=lssrv

After build, C<script/check-palindrome> and C<script/lssrv> will be created.

=head1 DESCRIPTION

After you add L<Rinci> metadata to your function, e.g.:

 package My::Palindrome;
 $SPEC{check_palindrome} = {
     v => 1.1,
     args => {
         text => { schema=>'str*', req=>1, pos=>0 },
         ci   => { schema=>'bool*', cmdline_aliases=>{i=>{}} },
     },
     result_naked => 1,
 };
 sub check_palindrome {
     my %args = @_;
     my $text = $args{ci} ? lc($args{text}) : $args{text};
     $text eq reverse($text);
 }

you can create a command-line script for that function that basically is not
much more than:

 #!perl
 use Perinci::CmdLine::Any;
 Perinci::CmdLine::Any->new(url => '/My/Palindrome/check_palindrome');

This Dist::Zilla plugin lets you automate the creation of such scripts.

B<Creating scripts.> To create a single script, put this in C<dist.ini>:

 [GenPericmdScript]
 ;required
 url=/My/Palindrome/check_palindrome
 ;optional
 abstract=Check if a text is a palindrome
 ; ...

To create more scripts, load the plugin again using the C<[Plugin/Name]> syntax,
e.g.:

 [GenPericmdScript / GenAnotherScript]
 ...

=for Pod::Coverage .+

=head1 CONFIGURATION (SCRIPT SPECIFICATION)

=head2 url* => str

Riap URL. If the script does not contain subcommand, this should refer to a
function URL. If the script contains subcommands, this should usually refer to a
package URL.

=head2 subcommands => str

For creating a CLI script with subcommands. Value is a whitespace-separated
entries of subcommand specification. Each subcommand specification must be in
the form of SUBCOMMAND_NAME=URL[:SUMMARY]. Example:

 delete=/My/App/delete_item add=/My/App/add_item refresh=/My/App/refresh_item:Refetch an item from source

=head2 subcommands_from_package_functions => bool

Will be passed to Perinci::CmdLine::Gen backend.

=head2 include_package_functions_match => re

Will be passed to Perinci::CmdLine::Gen backend.

=head2 exclude_package_functions_match => re

Will be passed to Perinci::CmdLine::Gen backend.

=head2 name => str

Name of script to create. Default will be taken from function (or package) name,
with C<_> replaced to C<->.

=head2 summary => str

Will be passed to Perinci::CmdLine::Gen backend (as C<script_summary>).

=head2 cmdline => str

Select module to use. Default is L<Perinci::CmdLine::Any>, but you can set this
to C<classic> (equals to L<Perinci::CmdLine::Classic>), C<any>
(L<Perinci::CmdLine::Any>), or C<lite> (L<Perinci::CmdLine::Lite>) or module
name.

=head2 prefer_lite => bool (default: 1)

If set to 0 and you are using C<Perinci::CmdLine::Any>, C<-prefer_lite> option
will be passed in the code.

=head2 enable_log => bool

Will be passed to Perinci::CmdLine object construction code (as C<log>).

=head2 default_log_level => str

If set, will add this code to the generated script:

 BEGIN { no warnings; $main::Log_Level = "..." }

This can be used if you want your script to be verbose by default, for example.

=head2 pass_cmdline_object => bool

Will be passed to Perinci::CmdLine object construction code.

=head2 extra_urls_for_version => str

Comma-separated string, will be passed to Perinci::CmdLine object construction
code (as array).

=head2 config_filename => str|array[str]

Will be passed to Perinci::CmdLine object construction code.

=head2 config_dirs => array[str]

Will be passed to Perinci::CmdLine object construction code.

=head2 ssl_verify_hostname => bool (default: 1)

If set to 0, will add this code to the generated script:

 $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;

This can be used if the Riap function URL is https and you don't want to verify.

=head2 load_modules => array[str]

Extra modules to load in the generated script.

=head2 code_before_instantiate_cmdline => str

=head2 code_after_end => str

=head2 default_format => str

Passed to Perinci::CmdLine object construction code.

=head2 skip_format => bool

Passed to Perinci::CmdLine object construction code.

=head2 use_utf8 => bool

Passed to Perinci::CmdLine object construction code.

=head2 allow_prereq => bool

Will be passed to Perinci::CmdLine::Gen backend.

=head2 per_arg_json => bool

Will be passed to Perinci::CmdLine::Gen backend.

=head2 per_arg_yaml => bool

Will be passed to Perinci::CmdLine::Gen backend.

=head1 CONFIGURATION (OTHER)

=head2 inline_generate_completer => bool (default: 1)

Perinci::CmdLine::Inline-generated scripts currently cannot do shell completion
on its own, but relies on a separate completer script (e.g. if the script is
C<script/foo> then the completer will be generated at C<script/_foo>). This
option can be used to suppress the generation of completer script.

=head2 build_load_modules => array[str]

Load modules during build process.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-GenPericmdScript>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-GenPericmdScript>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-GenPericmdScript>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Rinci>

L<Pod::Weaver::Plugin::Rinci> to fill more stuffs to the POD of the generated
script.

C<Dist::Zilla::Plugin::Rinci::*> for plugins that utilize Rinci metadata.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
