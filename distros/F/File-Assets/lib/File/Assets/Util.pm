package File::Assets::Util;

use strict;
use warnings;

use File::Assets::Carp;

use MIME::Types();
use Scalar::Util qw/blessed/;
use Module::Pluggable search_path => q/File::Assets::Filter/, require => 1, sub_name => q/filter_load/;
use Digest;
use File::Assets::Asset;

{
    my $types;
    sub types {
        return $types ||= MIME::Types->new(only_complete => 1);
    }
}

sub digest {
    return Digest->new("MD5");
}

sub parse_name {
    my $class = shift;
    my $name = shift;
    $name = "" unless defined $name;
    $name = $name."";
    return undef unless length $name;
    return $name;
}

sub same_type {
    no warnings 'uninitialized';
    my $class = shift;
    my $aa = $class->parse_type($_[0]) or confess "Couldn't parse: $_[0]";
    my $bb = $class->parse_type($_[1]) or confess "Couldn't parse: $_[1]";
    
    return $aa->simplified eq $bb->simplified;
}

sub type_extension {
    my $class = shift;
    my $type = $class->parse_type($_[0]);
    croak "Couldn't parse @_" unless $type;
    return ($type->extensions)[0];
}

sub parse_type {
    no warnings 'uninitialized';
    my $class = shift;
    my $type = shift;
    return unless defined $type;
    return $type if blessed $type && $type->isa("MIME::Type");
    $type = ".$type" if $type !~ m/\W+/;
    # Make sure we get stringified version of $type, whatever it is
    $type .= "";
    $type = "application/javascript" if $type =~ m{^text/javascript$}i;
    $type = lc $type;
    return $class->types->mimeTypeOf($type) || $class->types->type($type);
}

sub parse_rsc {
    my $class = shift;
    my $resource = shift;
    my ($uri, $dir, $path) = @_;
    if (ref $resource eq "ARRAY") {
        ($uri, $dir, $path) = @$resource;
    }
    elsif (ref $resource eq "HASH") {
        ($uri, $dir, $path) = @$resource{qw/uri dir path/};
    }
    elsif (blessed $resource) {
        if ($resource->isa("Path::Resource")) {
            return $resource->clone;
        }
        elsif ($resource->isa("URI::ToDisk")) {
            $uri = $resource->URI;
            $dir = $resource->path;
        }
    }
    return Path::Resource->new(uri => $uri, dir => $dir, path => $path);
}

my @_filters;
sub _filters {
    return @_filters ||
        grep { ! m/::SUPER$/ } reverse sort  __PACKAGE__->filter_load();
}

sub parse_filter {
    my $class = shift;
    my $filter = shift;

    my $_filter;
    for my $possible ($class->_filters) {
        last if $_filter = $possible->new_parse($filter, @_);
    }

    return $_filter;
}

sub _substitute($$$;$$) {
    my $target = shift;
    my $character = shift;
    my $value = shift;
    my $deprecated = shift;
    my $original_path = shift;

    $value = "" unless defined $value;

    my $found;
    $found ||= $$target =~ s/\%$character/$value/g;
    $found ||= $$target =~ s/\%\.$character/$value ? "\.$value" : ""/ge;
    $found ||= $$target =~ s/\%\-$character/$value ? "\-$value" : ""/ge;
    $found ||= $$target =~ s/\%\/$character/$value ? "\/$value" : ""/ge;

    carp "\%$character is deprecated as a path pattern (in \"$original_path\")" if $found && $deprecated;
}

sub build_output_path {
    my $class = shift;
    my $template = shift;
    my $filter = shift;

    my $path = $template;
    $path = $path->{path} if ref $path eq "HASH";

    return $$path if ref $path eq "SCALAR";

    $path = '%n%-l%-f.%e' unless $path;
    $path = "$path/" if blessed $path && $path->isa("Path::Class::Dir");
    $path .= '%n%-l%-f.%e' if $path && $path =~ m/\/$/;
    $path .= '.%e' if $path =~ m/(?:^|\/)[^.]+$/;

    local %_;
    if (ref $filter eq "HASH") {
        %_ = %$filter;
    }
    else {
        %_ = (
            fingerprint => $filter->fingerprint,
            name => $filter->assets->name,
            kind => $filter->kind->kind,
            head => $filter->kind->head,
            tail => $filter->kind->tail,
            extension => $filter->kind->extension,
        );
    }

    my $original_path = $path; 

    $path =~ s/%b/%-l/g and carp "\%b is deprecated as a path pattern (in \"$original_path\")";

    _substitute \$path, e => $_{extension};
    _substitute \$path, f => $_{fingerprint};
    _substitute \$path, n => $_{name};
    _substitute \$path, k => $_{kind};
    _substitute \$path, h => $_{head};
    _substitute \$path, l => $_{tail};

    _substitute \$path, d => $_{fingerprint}, 1 => $original_path;
    _substitute \$path, D => $_{fingerprint}, 1 => $original_path;
    _substitute \$path, a => $_{tail}, 1 => $original_path;

    $path =~ s/%%/%/g;

    return $path;
}

1;
