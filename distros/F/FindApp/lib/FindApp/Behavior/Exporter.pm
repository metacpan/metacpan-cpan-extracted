package FindApp::Behavior::Exporter;

################################################################
# Class importer and its helpers.
################################################################

# Guarantee feature.pm already loaded, which
# is now unlike use v5.10, which no longer does so!
use feature ":5.10";
use strict;
use warnings;
use mro "c3";

use parent qw(Exporter);

use FindApp::Vars qw(:all);
use FindApp::Utils qw(:all);

use namespace::clean;

use pluskeys qw{
    ORIGINAL_EXPORTS
};

sub init { &ENTER_TRACE;
    my($self) = @_;
    $self->maybe::next::method;
    $self->original_exports([]);
}

sub import { &ENTER_TRACE;
    $_[0]->original_exports(@_);
    my $caller  = caller;
    my $self    = shift;

    # Future-proof the feature load, just in case they yet
    # again add new sneaky compiler optimization someday.
    require feature;
    feature::->import(":5.10");

    # Can't operate on @_ itself because
    # its values are readonly in an import!
    my @ARGS    = @_;
    my $adder   = function import_adder => sub {
       my($which, $dir) = @_;
       my $file = shift(@ARGS) || botch_import_missing();
       $self->group($dir)->$which->add($file);
    };

    my $add_dir = join "|", alldir_map { quotemeta lc };
    my $let_dir = join "|", subdir_map { quotemeta uc };
    my $finder  = "findapp_and_export";

    my(@pre_args, @post_args, @subclasses);

SWITCH:
    while (@ARGS && $ARGS[0] =~ s/^--?//) {
      for (shift @ARGS) {
        /^($add_dir)$/         && case { $adder->(wanted  => $1)       };
        /^($let_dir)$/         && case { $adder->(allowed => $1)       };
        /^ debug        $/x    && case { $self->debugging(1)           };
        /^ here         $/x    && case { $self->default_origin("cwd")  };
        /^ nofind       $/x    && case { $finder   = ""                };
        /^ noload       $/x    && case { $finder &&= "findapp"         };
        /^ trace (\d+)? $/x    && case { $self->tracing($1 || 1)       };
        /^ vars         $/x    && case { push @pre_args, ":vars"       };
 # This works, but it's more trouble to maintain than it's worth.  It's 
 # for dynamic role loading. I may bring it back if I come up with more
 # roles that it makes sense to leave optional.
 #      /^ subclass     $/x    && case { push @pre_args, ":subclass"    ;
 #                                       FindApp::Vars->import(":all");
 #                                       $self->adopts_children($caller);
 #                              };
 #
 #      # convert the shortcuts into normal classes to load
 #      s/^($classic)$/my::\u$1/;
 #      s/^my//                 && case {
 #                                        my $mod = ((length) ? $_ : shift @ARGS)
 #                                             || botch_import_missing("my");
 #                                        push @subclasses, $mod;
 #                              };
 #######################################################################
        botch_import_unknown();
      }
    }

    # Classes and files aren't "real" imports:
    @ARGS = filter_implicits($self, @ARGS);

    { # Don't use self here because subclasses don't have "the right stuff".
        my @import_args = (@pre_args, @ARGS, @post_args);
        __PACKAGE__->export_to_level(1, $caller, @import_args);
    }

    # Load our parents and become a (potentially new) subclass of them.
    $self->adopts_parents(@subclasses) if @subclasses;

    # Don't run the finder if we're just subclassing: that's their job,
    # either explicitly or else implicitly when this import method is
    # in turn run on them.
    if ($finder && !$caller->isa(__PACKAGE__)) {
        $self->$finder;
    }

} ## sub import

sub original_exports { &ENTER_TRACE;
    my $self = &myself;
    if (@_) {
        if (@_ == 1 && grep { ref && reftype eq "ARRAY" } @_) {
               $$self{+ORIGINAL_EXPORTS}   = shift;
        } else {
            @{ $$self{+ORIGINAL_EXPORTS} } = @_;
        }
    }
    return  @{ $$self{+ORIGINAL_EXPORTS} };
}

no namespace::clean;

# Look for things that are either modules with colons
# to add to libs wanted or paths with slashes to add to
# root wanted.
sub filter_implicits {
    my($self, @input) = @_;
    my @output;
SWITCH:
    for (@input) {
        m| ^ !? :           |x     && case { push @output, $_ }; # import :tag
        m| ^ !? / [^/]+ / $ |x     && case { push @output, $_ }; # import /pat/
        m| ^    /           |x     && case { $self->origin($_)             };
        m|      ::          |x     && case { $self->add_libdirs_wanted($_) };
        m| [/.-]            |x     && case { $self->add_rootdir_wanted($_) };
        push @output, $_;
    }
    return @output;
}

sub botch_import_pragma($);

sub botch_import_missing(_) {
    my($pragma) = @_;
    botch_import_pragma("expected argument to '-$pragma' import pragma");
}

sub botch_import_unknown(_) {
    my($pragma) = @_;
    botch_import_pragma("import pragma '-$pragma' is unrecognized");
}

sub botch_import_pragma($) {
    my($error) = @_;
    die __PACKAGE__ . " $error; " . q{valid import pragmas are:

  -root wanted_file_or_dir_in_root

  -lib  wanted_dir_in_libs
  -bin  wanted_dir_in_bins
  -man  wanted_dir_in_mans

  -LIB  allowed_dir_in_libs
  -BIN  allowed_dir_in_bins
  -MAN  allowed_dir_in_mans

  -vars       (import $Root, @Lib, $Lib, @Bin, $Bin, @Man, $Man)
  -here       (to default to cwd not script dir)

  -subclass   (use this to make your package also a subclass of this class)

  -git        (like -my::Git, so like -my FindApp::Git)
  -devperl    (like -my::Devperl, so like -my FindApp::Devperl)

  -my name_of_subclass (like -my Other::Class, but -my::Git means -my FindApp::Git)

  -nofind     (don't try to find the approot yet)
  -noload     (find the approot but don't load @INC or environment variables)

  -debug      (enable debugging but not tracing, or by setting $FindApp::Debugging to true)

  -trace      (enable tracing, or by setting $FindApp::Tracing to 1, 2, or 3)
  -trace1     (same as -trace)
  -trace2     (enable more tracing, or by setting $FindApp::Tracing to 2)
  -trace3     (enable still more tracing, or by setting $FindApp::Tracing to 3)

    };
}

sub exported_envars() {
    state $vars = [
        qw($Root),
        subdir_map { map { ('$'.$_, '@'.$_) } ucfirst },
    ];
    return @$vars;
}

sub exporter_vars() {
    return qw(
        @CARP_NOT
        @EXPORT_OK
        %EXPORT_TAGS
    );
}

sub exported_subs {
    @{$FindApp::Utils::EXPORT_TAGS{all}};

}

use namespace::clean;

our %EXPORT_TAGS;

$EXPORT_TAGS{vars}          = [ exported_envars() ];
$EXPORT_TAGS{subclass_subs} = [  exported_subs() ];
$EXPORT_TAGS{subclass_vars} = [ exported_envars(), exporter_vars() ],

$EXPORT_TAGS{subclass} = [
    (map { @$_ } @EXPORT_TAGS{ <subclass_{sub,var}s> }),
];

our @EXPORT_OK = (import => sort map { @$_ } values %EXPORT_TAGS);

1;

=encoding utf8

=head1 NAME

FindApp::Exporter - FIXME

=head1 SYNOPSIS

 use FindApp::Exporter;

=head1 DESCRIPTION

=head2 Pluskey Attributes

These are always private; use the methods insteads.

=over

=item ORIGINAL_EXPORTS

=back

=head2 Public Methods

=over

=item botch_import_missing

=item botch_import_pragma

=item botch_import_unknown

=item exported_envars

=item exporter_vars

=item filter_implicits

=item import

=item import_adder

=item original_exports

=back

=over

=item FIXME

=back

=head1 EXAMPLES

=head1 ENVIRONMENT

=head1 SEE ALSO

=over

=item L<FindApp>

=back

=head1 CAVEATS AND PROVISOS

=head1 BUGS AND LIMITATIONS

=head1 HISTORY

=head1 AUTHOR

Tom Christiansen << <tchrist@perl.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2016, Tom Christiansen C<< <tchrist@perl.com> >>.
All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

