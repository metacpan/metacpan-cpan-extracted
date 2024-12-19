use warnings;
use 5.020;
use experimental qw( signatures );
use stable qw( postderef );
use true;

package FFI::Build::File::VMod 0.01 {

    # ABSTRACT: Class to track V source in FFI::Build

    use parent qw( FFI::Build::File::Base );
    use constant default_suffix => '.mod';
    use constant default_encoding => ':utf8';
    use File::Which qw( which );
    use PerlX::Maybe qw( maybe );
    use Path::Tiny ();
    use File::chdir;


    sub accept_suffix {
        (qr/\/v\.mod\z/)
    }

    sub build_all ($self, $) {
        $self->build_item;
    }

    sub build_item ($self) {

        my $vmod = Path::Tiny->new($self->path);

        my $platform;
        my $buildname;
        my $lib;

        my($name) = map { /name:\s*'(.*)'/ ? ($1) : () } $vmod->lines_utf8;
        die "unable to find name in $vmod" unless defined $name;

        if($self->build) {
            $platform = $self->build->platform;
            $buildname = $self->build->buildname;
            $lib = $self->build->file;
        } else {
            $platform = FFI::Build::Platform->new;
            $buildname = "_build";

            $lib = FFI::Build::File::Library->new(
                $vmod->sibling("$name" . scalar($platform->library_suffix))->stringify,
                platform => $self->platform,
            );
        }

        if($self->_have_v_compiler) {

            return $lib if -f $lib->path && !$lib->needs_rebuild($self->_deps($vmod->parent));

            my $lib_path = Path::Tiny->new($lib->path)->relative($vmod->parent);
            say "+cd @{[ $vmod->parent ]}";
            local $CWD = $vmod->parent;
            say "+mkdir -p @{[ $lib_path->parent->mkdir ]}";
            $lib_path->parent->mkdir;
            $platform->run('v', '-prod', '-shared', -o => "$lib_path", '.');
            die "command failed" if $?;
            die "no shared library" unless -f $lib_path;
            say "+cd -";

        } else {

            my $c_source = $vmod->sibling("$name.c");
            die "module requires v compiler" unless -f $c_source;
            return $lib if -f $lib->path && !$lib->needs_rebuild($c_source->stringify);
            require FFI::Build;

            my @args;
            if($self->build) {
                foreach my $key (qw( alien buildname cflags export file libs verbose )) {
                    push @args, $key => $self->build->$key;
                }
            } else {
                push @args,
                    buildname => $buildname,
                    file => $lib,
                ;
            }

            warn "c_source = $c_source";

            my $bx = FFI::Build->new(
                $name,
                source => ["$c_source"],
                platform => $platform,
                dir => $vmod->parent->stringify,
                @args,
            );

            return $bx->build;

        }

        return $lib;

    }

    sub _deps ($self, $path)
    {
        my @ret;
        foreach my $path ($path->children) {
            next if -l $path;  # skip symlinks to avoid recursion
            push @ret, $self->_deps($path) if -d $path;
            push @ret, $path->stringify if $path->basename =~ /^(.*\.(v|c|h)|v\.mod)\z/;
        }
        return @ret;
    }

    sub _have_v_compiler ($self) {
        return 0 if $ENV{FFI_PLATYPUS_LANG_VMOD_SKIP_V};
        return 1 if which 'v';
        return 0;
    }

}

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::Build::File::VMod - Class to track V source in FFI::Build

=head1 VERSION

version 0.01

=head1 SYNOPSIS

Makefile.PL:

 use strict;
 use warnings;
 use ExtUtils::MakeMaker;
 use FFI::Build::MM;
 
 my $fbmm = FFI::Build::MM->new;
 
 WriteMakefile($fbmm->mm_args(
     ABSTRACT => 'Perl/V Extension',
     DISTNAME => 'V-FFI',
     NAME => "V::FFI",
     VERSION => '1.00',
 ));
 
 sub MY::postamble {
   $fbmm->mm_postamble;
 }

ffi/v.mod:

 Module {
     name: 'foo'
     ...
 }

ffi/foo.v:

 module foo
 
 pub fn add(a, b i32) i32 {
     return a + b
 }

lib/Foo.pm:

 use warnings;
 use 5.020;
 use experimental qw( signatures );
 
 package Add {
     use FFI::Platypus 2.00;
     use Exporter qw( import );
 
     our @EXPORT = qw( add );
 
     my $ffi = FFI::Platypus->new( api => 2, lang => 'V' );
     $ffi->bundle;
     $ffi->mangler(sub ($sym) { return "libfoo__$sym" });
 
     $ffi->attach(add => ['i32','i32'] => 'i32');
 }

=head1 DESCRIPTION

=head1 METHODS

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
