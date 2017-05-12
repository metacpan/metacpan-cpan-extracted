package inc::MBFlExt;
{
    use strict;
    use warnings;
    $|++;
    use Config qw[%Config];
    use ExtUtils::ParseXS qw[];
    use File::Spec::Functions qw[catdir rel2abs abs2rel canonpath curdir];
    use File::Basename qw/basename dirname/;
    use File::Find qw[find];
    use File::Path qw[make_path];
    use base 'Module::Build';
    our %dl_funcs;
    {

        package My::ExtUtils::CBuilder;
        use base 'ExtUtils::CBuilder';

        sub do_system {
            my ($self, @cmd) = @_;
            @cmd = grep { defined && length } @cmd;
            @cmd = map { s[\s+$][]; s[^\s+][]; $_ } @cmd;
            print "@cmd\n" if !$self->{'quiet'};
            my $cmd = join ' ', @cmd;
            `$cmd`;
            return 1;
        }

        sub prelink {
            my ($self, %args) = @_;
            ($args{dl_file} = $args{dl_name}) =~ s/.*:://
                unless $args{dl_file};
            $args{'dl_funcs'} = \%inc::MBFl::dl_funcs;    # Frakin' CBuilder
            require ExtUtils::Mksymlists;
            ExtUtils::Mksymlists::Mksymlists( # dl. abbrev for dynamic library
                DL_VARS  => $args{dl_vars}      || [],
                DL_FUNCS => $args{dl_funcs}     || {},
                FUNCLIST => $args{dl_func_list} || [],
                IMPORTS  => $args{dl_imports}   || {},
                NAME   => $args{dl_name},     # Name of the Perl module
                DLBASE => $args{dl_base},     # Basename of DLL file
                FILE   => $args{dl_file},     # Dir + Basename of symlist file
                VERSION =>
                    (defined $args{dl_version} ? $args{dl_version} : '0.0'),
            );

            # Mksymlists will create one of these files
            return grep -e, map "$args{dl_file}.$_", qw(ext def opt);
        }
    }
    {

        sub ACTION_code {
            require Alien::FLTK;              # Should be installed by now
            require Template::Liquid;
            my ($self, $args) = @_;
            my $AF = Alien::FLTK->new();
            my $CC = My::ExtUtils::CBuilder->new();
            my (@xs, @rc, @pl, @obj);
            find(sub { push @xs, $File::Find::name if m[.+\.xs$]; },  'xs');
            find(sub { push @pl, $File::Find::name if m[.+\.pl$]i; }, 'xs/rc')
                if -d '/xs/rc';

            if ($self->is_windowsish && -d 'xs/rc') {
                $self->do_system($^X, $_) for @pl;
                find(sub { push @rc, $File::Find::name if m[.+\.rc$]; },
                     'xs/rc');
                my @dot_rc = grep defined,
                    map { m[\.(rc)$] ? rel2abs($_) : () } @rc;
                for my $dot_rc (@dot_rc) {
                    my $dot_o = $dot_rc =~ m[^(.*)\.] ? $1 . '.res' : next;
                    push @obj, $dot_o;
                    next if $self->up_to_date($dot_rc, $dot_o);
                    printf 'Building Win32 resource: %s... ',
                        abs2rel($dot_rc);
                    chdir $self->base_dir . '/xs/rc';
                    require Config;
                    my $cc = $Config{'ccname'} || $Config{'cc'};
                    if ($cc eq 'cl') {    # MSVC
                        print $self->do_system(
                                      sprintf 'rc.exe /l 0x409 /fo"%s" %s',
                                      $dot_o, $dot_rc) ? "okay\n" : "fail!\n";
                    }
                    else {                # GCC
                        print $self->do_system(
                                      sprintf 'windres -O coff -i %s -o %s',
                                      $dot_rc, $dot_o) ? "okay\n" : "fail!\n";
                    }
                    chdir rel2abs($self->base_dir);
                }
                map { abs2rel($_) if -f } @obj;
            }
            my @pod;
            find(sub { push @pod, $File::Find::name if m[.+\.pod$] }, 'lib');
            if (!$self->up_to_date([@pod], 'xs/Fl.cxx')) {
                printf 'Generating source... ';
                #
                our (@xsubs, %includes, %exports);
                sub xs { push @{$xsubs[-1]->{methods}}, shift }
                sub class { push @xsubs, {package => shift} }
                my $isa = *isa;
                *isa = sub { $xsubs[-1]{isa} = shift; };
                sub export_constant { $exports{+pop}          = pop; }
                sub include         { $includes{+pop}++; }
                sub widget_type     { $xsubs[-1]{widget_type} = shift; }
                #
                require $_ for @pod;
                *isa = $isa;
                open my $in, '<', 'xs/Fl_cxx.template';
                sysread $in, my $raw, -s $in;
                #
                my $template = Template::Liquid->parse($raw);
                open(my $fh, '>', 'xs/Fl.cxx') || die $!;
                #
                my $output =
                    $template->render(xsubs    => \@xsubs,
                                      exports  => \%exports,
                                      includes => \%includes
                    );
                syswrite $fh, $output;
                close $fh;
                $self->add_to_cleanup('xs/Fl.cxx');
                print 'okay (' . length($output) . " bytes)\n";
            }
            my @cpp;
            find(sub { push @cpp, $File::Find::name if m[.+\.cxx$]; }, 'xs');
        XS: for my $XS ((sort { lc $a cmp lc $b } @xs)) {
                push @cpp, _xs_to_cpp($self, $XS)
                    or exit !printf 'Cannot Parse %s', $XS;
            }
        CPP: for my $cpp (@cpp) {
                if ($self->up_to_date($cpp, $CC->object_file($cpp))) {
                    push @obj, $CC->object_file($cpp);
                    next CPP;
                }
                local $CC->{'quiet'} = $self->quiet();
                printf q[Building '%s' (%d bytes)... ], $cpp, -s $cpp;
                my $obj =
                    $CC->compile(
                             source => $cpp,
                             include_dirs =>
                                 [curdir, dirname($cpp), $AF->include_dirs()],
                             'C++' => 1
                    );
                printf "%s\n",
                    ($obj && -f $obj) ? 'okay' : 'failed';    # XXX - exit?
                push @obj, $obj;
            }
            make_path(catdir(qw[blib arch auto Fl]),
                      {verbose => !$self->quiet(), mode => 0777});
            @obj = map { canonpath abs2rel($_) } @obj;
            my $lib = catdir(qw[blib arch auto Fl], 'Fl.' . $Config{'so'});
            if (!$self->up_to_date([@obj], $lib)) {
                printf q[Building '%s'... ], $lib;
                my ($dll, @cleanup)
                    = $CC->link(objects            => \@obj,
                                lib_file           => $lib,
                                module_name        => 'Fl',
                                extra_linker_flags => '-L'
                                    . $AF->library_path . ' '
                                    . $AF->ldflags
                                    . ' -lstdc++'
                    );
                printf "%s\n",
                    ($lib && -f $lib) ?
                    'okay (' . (-s $lib) . ' bytes)'
                    : 'failed';    # XXX - exit?
                @cleanup = map { s["][]g; rel2abs($_); } @cleanup;
                $self->add_to_cleanup(@cleanup);
                $self->add_to_cleanup(@obj);
            }
            $self->SUPER::ACTION_code;
        }

        sub _xs_to_cpp {
            my ($self, $xs) = @_;
            $xs = rel2abs($xs);
            my ($cpp, $typemap) = ($xs, $xs);
            $cpp =~ s[\.xs$][\.cxx];
            $typemap =~ s[\.xs$][\.tm];
            $typemap = 'type.map' if !-e $typemap;
            my @xsi;
            find sub { push @xsi, $File::Find::name if m[\.(pod|xsi)$] },
                catdir('lib/Fl');
            $self->add_to_cleanup($cpp);
            return $cpp
                if $self->up_to_date([@xsi, $xs,
                                      rel2abs(catdir('xs', $typemap))
                                     ],
                                     $cpp
                );
            printf q"Parsing '%s' into '%s' w/ '%s'... ", $xs, $cpp, $typemap;
            local @ExtUtils::ParseXS::BootCode = ();

            if (ExtUtils::ParseXS->process_file(
                                   filename => $xs,
                                   output   => $cpp,
                                   'C++'    => 1,
                                   hiertype => 1,
                                   typemap => rel2abs(catdir('xs', $typemap)),
                                   prototypes  => 1,
                                   linenumbers => 1
                )
                )
            {   print "okay\n";
                return $cpp;
            }
            print "FAIL!\n";
            return;
        }
    }
    1;
}
