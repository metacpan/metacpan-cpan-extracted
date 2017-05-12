package Exporter::Dispatch;
use Carp qw(croak);
our $VERSION = 2.10;

sub import {
    my $pkg = (caller)[0];
    if (@_ > 2) {
        croak 'Incorrect import list for Exporter::Dispatch';
    }
    elsif ($_[-1] eq 'create_dptable') {
        *{"${pkg}::create_dptable"} = \&create_dptable;
        return
    }
    elsif ($_[-1] eq 'dptable_alias') {
        *{"${pkg}::dptable_alias"} = sub {
            *{"${pkg}::$_[1]"} = *{"${pkg}::$_[0]"}
        }
    }
    elsif (@_ == 2) {
        croak 'Incorrect import list for Exporter::Dispatch';
    }
    *{"${pkg}::create_dptable"} = sub { create_dptable($pkg) };
}

sub create_dptable {
    my $pkg = shift;
    my %dispatch;
    my @oksymbols = grep {   !/^_/
                          && !/^dptable_alias$/
                          && !/^create_dptable$/
                          && defined *{"${pkg}::$_"}{CODE} }
                    keys %{*{"${pkg}::"}};
    $dispatch{$_} = *{"${pkg}::$_"}{CODE}
        foreach ( @oksymbols );
    return \%dispatch
};

1;

=head1 NAME

Exporter::Dispatch

=head1 ABSTRACT

Simple and modular creation of dispatch tables.

=head1 SYNOPSIS

    package TestPkg;
    use Exporter::Dispatch qw(dptable_alias);
    dptable_alias("sub_a", "sub_aa"); # typeglobbing for dummies;
    
    sub sub_a { ... }
    sub sub_b { ... }
    sub sub_c { ... }
    sub _sub_c_helper { # not part of the table!
        # ...
    }
    
    package main;
    my $table = create_dptable TestPkg; # or TestPkg::create_dptable();
    $table->{'sub_c'}->("Hello!");
    
    # ------------------------------------------------------
    # or
    
    package TestPkg;
    sub sub_a { ... }
    sub sub_b { ... }
    sub sub_c { ... }
    sub _sub_c_helper { # not part of the table!
        # ...
    }
    
    package main;
    use Exporter::Dispatch;
    my $table = create_dptable 'TestPkg'; # Please know what you are doing here.
    $table->{'sub_c'}->("Hello!");

=head1 DESCRIPTION

Dispatch tables are great and convienient, but sometimes can be a bit of a
pain to write. You have references flying over here and closures flying over
there; yuck!  Thats much too complicated for so simple of an idea. Wouldn't
it be great if you could say "Ok, I have a set of subs here, and I want a
dispatch table that maps each subname to each sub... Go do it, Perl genie!"
With this short snippet of a module, now you can. Just throw your subs in a
module, C<use Exporter::Dispatch;>, and a C<create_dptable> subroutine that
(surpise!) creates a dispatch table that maps each subname in the package to
its corresponding sub will magically appear to serve you.

In a more serious tone, C<Exporter::Dispatch> essentially creats a
subroutine (named create_dptable) in namespaces it is imported to.  This
subroutine, when called, returns a hashref that maps a string of each
subname to the corresponding subroutine.  Subroutines that begin with an
underscore are not added to the returned table, so they can be used as
"helper" routines.
    
=head2 Exports
    
=over 3

=item B<create_dptable>

Indirect object syntax version; is automatically imported into the calling
package unless the functional form of create_dptable is exported.  Please note
that this form ofcreate_dptable takes no arguments; the version used in the
first part of the synopsis uses Perl's indirect object syntax.

=item B<create_dptable("PacakgeName")>

Functional version of create_dptable; this is a version that can create a
dispatch table based on any package.  Please note that you should only use this
form when creating a dispatch table based on a package that you have control of.
(i.e., that you wrote)

=item B<dptable_alias("sub_name", "sub_name_alias")>

Typeglobbing for dummies.  Automatically imported into the calling package.
C<dptable_alias> will create an entry in the symbol table that maps "sub_name"
to "sub_name_alias" 

=back

=head1 BUGS

If you find any bugs or oddities, please do inform me.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN) (http://search.cpan.org/CPAN/). Or see
http://search.cpan.org/author/JRYAN/.

=head1 VERSION

This document describes version 2.10 of Exporter::Dispatch.

=head1 AUTHOR

Joseph F. Ryan <ryan.311@osu.edu>

=head1 COPYRIGHT

Copyright 2004 Joseph F. Ryan. All rights reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
