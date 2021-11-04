package FindApp::Utils::Package;

use v5.10;
use strict;
use warnings;

use Carp qw(carp cluck confess croak);
use FindApp::Utils::Assert  qw(:all);
use FindApp::Utils::Debug   qw(:all);
use FindApp::Utils::Syntax  qw(:all);

# Chicken-and-egg scrambles subuse "Object";
use FindApp::Utils::Package::Object <{UN,}PACKAGE>;

sub export_alias              (  $$ ) ;
sub export_function           (  $$ ) ;
sub export_ok                         ;
sub sort_packages_lexically           ;
sub sort_packages_numerically         ;
sub stash                     (  _  ) ;
sub stashes                           ;
sub subs_in                           ;

#################################################################

use Exporter     qw(import);
our $VERSION   = v1.0;
our @EXPORT    = <{,UN}PACKAGE>;
our @EXPORT_OK = (
    <{,UN}PACKAGE>,
    qw(
        stashes
        subs_in
    ), 
    <sort_packages{,_{lex,numer}ically}>,
);

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

sub export_ok {
    push @EXPORT_OK, @_;
}

sub export_function($$) {
    my($name, $code) = @_;
    function($name, $code);
    export_ok($name);
}

sub export_alias($$) {
    my($name, $code) = @_;
    no strict "refs";
    *$name = $code;
    export_ok($name);
}

sub sort_packages_lexically {
    wantarray                   || croak "need list context for sorting";
    map   {  UNPACKAGE  }
    sort #{ $a cmp $b   }   # already default
    map   { PACKAGE($_) } 
    @_ ;
}

export_alias sort_packages => \&sort_packages_lexically;

sub sort_packages_numerically {
    wantarray                   || croak "need list context for sorting";
    map   {  UNPACKAGE  }
    sort  { $a  <=>  $b }
    map   { PACKAGE($_) } 
    @_;
}


sub stash(_) { PACKAGE(shift)->stash };

sub stashes {
    my @stashes = map { stash } @_;
    return wantarray ? @stashes : $stashes[0];
};

sub subs_in {
    my %seen;
    for my $stash (stashes @_) {
        while (my($name, $glob) = each %$stash) {
            ref \$glob eq "GLOB"    &&   # weird things find their way into the stashes
            *$glob{CODE}            && 
            $seen{$name}++          
            ## && warn "already saw $name";
        }
    }
    return sort keys(%seen);
}

my %prefix_methods = qw(
    sib  super
    sub  self
    top  left
);

while (my($prefix, $SUBMETH) = each %prefix_methods) {
    # BUILD: subpackage, sibpackage, toppackage
    export_function "${prefix}package" => sub { &ENTER_TRACE;
        wantarray       // croak "useless use of ${prefix}package in void context";
        croak "need list context for multiple arguments" if @_  > 1 && !wantarray;
        croak "need arguments for list context"          if @_ == 0 &&  wantarray;
        @_ = ("") unless @_;
        my @packages = PACKAGE(caller)->$SUBMETH->add_all_unblessed(@_);
        return wantarray ? @packages : $packages[0];
    };
    # BUILD: subuse, sibuse, topuse
    export_function "${prefix}use" => sub { &ENTER_TRACE;
        my($pack, @imports) = @_;
        my $caller = PACKAGE(caller);
        my $package = $caller->$SUBMETH->add($pack);
        my $import = "";
        if (@imports) {
            $import = (@imports == 1 && !defined $imports[0]) 
                        ? "()"  # hack to allow a null import list
                        : "qw(@imports)" 
        }
        eval qq{ package $caller; use $package $import; 1 } || die;
    };
}

# The with behaviors have to come first so that the
# base class doesn't have to know they exist, since
# a new one may override something that doesn't know
# it's being overridden.
export_function implements => sub { &ENTER_TRACE;
    return @_ => <Class State Behavior>;
};

export_function implementation => sub { &ENTER_TRACE;
    wantarray   || panic "need list context for implementation";
    PACKAGE(caller)->add_all_unblessed(&implements);
};

export_function with => sub { &ENTER_TRACE;
    wantarray   || panic "need list context for role loading";
    @_          || panic "with what?";
    PACKAGE("Behavior")->add_all_unblessed(@_);
};

1;

################################################################

################################################################

=encoding utf8

=head1 NAME

FindApp::Utils::Package - FIXME

=head1 SYNOPSIS

 use FindApp::Utils::Package;

=head1 DESCRIPTION

=head2 Public Methods

=over

=item FIXME

=back

=head2 Exports

=over

=item export_alias

=item export_function

=item export_ok

=item implementation

=item implements

=item sibpackage

=item sibuse

=item sort_packages

=item sort_packages_lexically

=item sort_packages_numerically

=item stash

=item stashes

=item subs_in

=item subpackage

=item subuse

=item toppackage

=item topuse

=item with

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

