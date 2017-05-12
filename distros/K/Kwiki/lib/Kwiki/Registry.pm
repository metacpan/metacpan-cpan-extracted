package Kwiki::Registry;
use Spoon::Registry '-Base';

sub add {
    my ($key, $value) = @_;
    return super
      unless $key eq 'preference' and @_ == 2;
    super($key, $value->id, object => $value);
}

sub not_a_plugin {
    my $class_name = shift;
    die <<END;

Error:
$class_name is not a plugin class.
see: http://www.kwiki.org/?InstallingPlugins
END
}

sub plugin_redefined {
    my ($class_id, $class_name, $prev_name) = @_;
    die <<END if $class_name eq $prev_name;

Error:
Plugin class $class_name defined twice.
see: http://www.kwiki.org/?InstallingPlugins
END
    die <<END;

Error:
Can't use two plugins with the same class id.
$prev_name and $class_name both have a class id of '$class_id'.
see: http://www.kwiki.org/?InstallingPlugins
END
}

sub validate {
    $self->validate_prerequisite or return;
    return 1;
}

sub validate_prerequisite {
    for my $hashlet (@{$self->lookup->{plugins}}) {
        my $class_id = $hashlet->{id};
        my $prereqs = $self->lookup->{add_order}{$class_id}{prerequisite}
          or next;
        for my $prereq (@$prereqs) {
            $self->missing_prerequisite($class_id, $prereq)
              unless defined $self->lookup->{classes}{$prereq};
        }
    }
    return 1;
}

sub missing_prerequisite {
    my ($class_id, $prereq) = @_;
    my $class_name = $self->lookup->{classes}{$class_id};
    die "Missing prerequisite plugin '$prereq' for $class_name\n";
}

__DATA__

=head1 NAME

Kwiki::Registry - Kwiki Registry Base Class

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
