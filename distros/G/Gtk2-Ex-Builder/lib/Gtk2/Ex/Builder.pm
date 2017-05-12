package Gtk2::Ex::Builder;
BEGIN {
  $Gtk2::Ex::Builder::VERSION = '0.003001';
}
use strict;
use warnings;
use Sub::Call::Tail;
use Class::Accessor qw(antlers);

extends qw(Exporter);

has '_id', is => 'rw';
has '_gobj', is => 'rw';
has '_childs', is => 'rw';
has '_code', is => 'ro';

has 'is_built', is => 'rw';

BEGIN {
    our @EXPORT__in = qw(hav info sets gets on);
    our @EXPORT__out = qw(builder);
    our @EXPORT = (@EXPORT__in, @EXPORT__out);
    
    my $__warn = sub {
        my $syntax = shift;
        sub { warn "you cannot call '${syntax}' directly." }
    };
    
    my $__tail = sub {
        my $syntax = shift;
        sub { tail &{"$syntax"} }
    };

    no strict 'refs';
    for my $syntax (@EXPORT__in) {
        *{"$syntax"} = $__tail->($syntax);
        *{"_${syntax}"} = $__warn->($syntax);
    }

    undef &__PACKAGE__::new;
}

sub builder (&) {
    my $code = shift;
    if (!defined($code) or ref($code) ne 'CODE') {
        die 'builder expects CODE block as a argument';
    }
    return bless {
        _id => undef,
        _gobj => undef,
        _childs => [],
        _code => $code,
        is_built => 0,
    }, __PACKAGE__;
}

sub build {
    my $self = shift;
    __check_for_method($self, 'build');
    my $code = $self->_code;
    
    no warnings 'redefine';
    
    local *hav = sub {
        my ($obj) = @_;
        die "Gtk2 widget or builder{} block is expected for argument of 'hav'"
            unless defined $obj;
        die "builder{} has no widget, 'isa' statement is required"
            unless defined $self->_gobj;
        my $gobj = do {
            if ($obj->isa(__PACKAGE__)) {
                $obj->build unless $obj->is_built;
                $obj->_gobj;
            }
            else {
                $obj;
            }
        };
        if ($self->_gobj->isa('Gtk2::Box')) {
            $self->_gobj->pack_start($gobj, 1, 1, 0); #TODO
        }
        else {
            $self->_gobj->add($gobj);
        }
    };
    local *info = sub {
        my @args = @_;
        die "wrong number of arguments for 'info'" unless @args % 2 == 0;
        while (my ($k, $v) = splice @args, 0, 2) {
            if ($k eq 'is') {
                $self->_id($v);
            }
            elsif ($k eq 'isa') {
                my $module = ( $v =~ m/^Gtk2::(.+)$/ ? $v : "Gtk2::$v" );
                $self->_gobj($module->new);
            }                
        }
    };
    local *sets = sub {
        my ($command, @para) = @_;
        my $method = "set_$command";
        die "you should 'info isa => '*' before 'sets' to create an gtk2 object"
            unless defined $self->_gobj;
        return $self->_gobj->$method(@para);
    };
    local *gets = sub {
        my ($command) = @_;
        my $method = "get_$command";
        die "you should 'info isa => '*' before 'gets' to create an gtk2 object"
            unless defined $self->_gobj;
        return $self->_gobj->$method();
    };
    local *on = sub {
        my ($signal, $code) = @_;
        die "you should 'info isa => '*' before 'on' to create an gtk2 object"
            unless defined $self->_gobj;
        return $signal->_gobj->signal_connect( $signal => $code );
    };
    
    $code->();
    $self->is_built(1);
    $self;
}

sub get_gobj {
    my ($self) = @_;
    __check_for_method($self, 'get_gobj');
    return $self->_gobj;
}

sub set_gobj {
    my ($self, $obj) = @_;
    __check_for_method($self, 'set_gobj');
    return $self->_gobj($obj);
}

sub set_id {
    my ($self, $id) = @_;
    __check_for_method($self, 'set_id');
    die "string is expected for id" if ref($id) ne '';
    return $self->_id($id);
}

sub has_id {
    my ($self) = @_;
    __check_for_method($self, 'has_id');
    return $self->get_id;
}

sub get_id {
    my ($self) = @_;
    __check_for_method($self, 'get_id');
    return unless defined $self->_id;
    return $self->_id;
}

sub get_widget {
    my ($self, $find_id) = @_;
    __check_for_method($self, 'get_widget');

    my $id = $self->get_id;
    return $self->get_gobj if defined $id and $id eq $find_id;

    for my $widget (@{ $self->_childs }) {
        my $id = $widget->get_id;
        return $widget->get_gobj if defined $id and $id eq $find_id;
    }
}


sub __check_for_method {
    my ($arg, $method) = @_;
    unless (defined $arg and ref($arg) eq __PACKAGE__) {
        die "'${method}' is only allowed for a method";
    }
}



1;

=pod

=head1 NAME

Gtk2::Ex::Builder - Gtk2::Widget Wrapper and Gtk2 Building DSL

=head1 SYNOPSIS

   use Gtk2 -init;
   use Gtk2::Ex::Builder;

   my $app = builder {
     info isa => 'Window';
     sets title => 'My Application';
     sets default_size => 400, 400;
     on delete_event => sub { Gtk2->main_quit };

     hav builder {
       info isa => 'Button';
       info is => 'my_button';
       sets label => 'Hello World';
       on clicked => sub { print "Hi\n" };
     };
   };

   $app->build;
   print $app->get_widget('my_button')->get_label, "\n";

   Gtk2->main;

=head1 PRE-ALPHA VERSION

This library is totally B<UNDER DEVELOPMENT>
and B<APIs COULD BE CHANGED WITHOUT NOTICE> currently.

Any recommendations or criticisms or ideas are welcome.

=head1 DESCRIPTION

L<Gtk2::Ex::Builder> is a Domain-specific Language to
compose several Gtk2 widgets, and also a wrapper for a Gtk2 widget.

=head1 SUPPORT

The project is managed at L<http://github.com/am0c/Gtk2-Ex-Builder>.

You can submit some issues here L<http://github.com/am0c/Gtk2-Ex-Builder/issues>.

Any related mentions are welcome on C<irc.freenode.org> in C<#perl-kr>,
and on L<http://twitter.com/am0c>.

=head1 AUTHOR

Hojung Youn <amorette@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Hojung Youn.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
