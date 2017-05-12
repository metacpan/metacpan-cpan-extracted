package Dist::Zilla::Role::PluginBundle::Merged;

our $VERSION = '1.00'; # VERSION
# ABSTRACT: Mindnumbingly easy way to create a PluginBundle

use MooseX::Role::Parameterized;
use sanity;

use Class::Load;
use Storable 'dclone';
use Scalar::Util 'blessed';

use String::RewritePrefix 0.005 rewrite => {
   -as => '_section_class',
   prefixes => {
      ''  => 'Dist::Zilla::Plugin::',
      '@' => 'Dist::Zilla::PluginBundle::',
      '=' => ''
   },
};
use String::RewritePrefix 0.005 rewrite => {
   -as => '_plugin_name',
   prefixes => {
      'Dist::Zilla::Plugin::'       => '',
      'Dist::Zilla::PluginBundle::' => '@',
      '' => '=',
   },
};

with 'Dist::Zilla::Role::PluginBundle::Easy';

parameter mv_plugins => (
   isa      => 'ArrayRef[Str]',
   required => 0,
   default  => sub { [] },
);

role {
   my $p = shift;

   method mvp_multivalue_args => sub {
      my @list = @{ $p->mv_plugins };
      return unless @list;

      my %multi;
      foreach my $name (@list) {
         my $class = _section_class($name);
         Class::Load::load_class($class);
         @multi{$class->mvp_multivalue_args} = () if $class->can('mvp_multivalue_args');
      }

      return keys %multi;
   };

   method add_merged => sub {
      my $self = shift;
      my @list = @_;
      my $arg = $self->payload;

      my @config;
      foreach my $name (@list) {
         if (my $ref = ref $name) {
            if    ($ref eq 'HASH')  { $arg = $name; }
            elsif ($ref eq 'ARRAY') { $self->add_plugins($name); }
            else                    { die "Cannot pass $ref to add_merged"; }

            next;
         }

         my $class = _section_class($name);
         Class::Load::load_class($class);

         # check mv_plugins list to make sure the class was passed
         unless (grep { $_ eq $name } @{ $p->mv_plugins }) {
            say $self->_fake_log_prefix." $name has MVPs, but was never passed in the mv_plugins list"
               if ($class->can('mvp_multivalue_args') and scalar($class->mvp_multivalue_args));
         }

         # handle mvp_aliases
         my %aliases = ();
         %aliases = %{$class->mvp_aliases} if $class->can('mvp_aliases');

         if ($name =~ /^\@/) {
            # just give it everything, since we can't separate them out
            $self->add_bundle($name => $arg);
         }
         else {
            my %payload;
            foreach my $k (keys %$arg) {
               $payload{$k} = $arg->{$k} if $class->can( $aliases{$k} || $k );
            }
            $self->add_plugins([ "=$class" => $name => \%payload ]);
         }
      }
   };

   method config_rename => sub {
      my $self     = shift;
      my $payload  = $self->payload;
      my $args     = dclone($payload);
      my $chg_list = ref $_[0] ? $_[0] : { @_ };

      foreach my $key (keys %$chg_list) {
         my $new_key = $chg_list->{$key};
         my $val     = delete $args->{$key};
         next unless ($new_key);
         $args->{$new_key} = $val if (defined $val);
      }

      return $args;
   };

   method config_short_merge => sub {
      my ($self, $mod_list, $config_hash) = @_;

      $mod_list = [ $mod_list ] unless ref $mod_list;

      # figure out if the options are actually going to work
      foreach my $name (@$mod_list) {
         next if $name =~ /^\@/;

         my $class = _section_class($name);
         Class::Load::load_class($class);

         # handle mvp_aliases
         my %aliases = ();
         %aliases = %{$class->mvp_aliases} if $class->can('mvp_aliases');

         foreach my $k (keys %$config_hash) {
            say $self->_fake_log_prefix." $name doesn't support argument '$k' as a standard attribute.  (Maybe you should use explicit arg passing?)"
               unless $class->can( $aliases{$k} || $k );
         }
      }

      return (
         { %$config_hash, %{$self->payload} },
         @$mod_list,
         $self->payload,
      );
   };

   # written entirely in hackish
   method _fake_log_prefix => sub {
      my $self = shift;
      my $plugin_name = _plugin_name(blessed $self);

      my @parts;
      push @parts, $self->name  if $self->name;
      push @parts, $plugin_name unless ($self->name =~ /\Q$plugin_name\E$/);

      '['.join('/', @parts).']';
   };
};

42;

__END__

=pod

=encoding utf-8

=head1 NAME

Dist::Zilla::Role::PluginBundle::Merged - Mindnumbingly easy way to create a PluginBundle

=head1 SYNOPSIS

    # Yes, three lines of code works!
    package Dist::Zilla::PluginBundle::Foobar;
    Moose::with 'Dist::Zilla::Role::PluginBundle::Merged';
    sub configure { shift->add_merged( qw[ Plugin1 Plugin2 Plugin3 Plugin4 ] ); }
 
    # Or, as a more complex example...
    package Dist::Zilla::PluginBundle::Foobar;
    use Moose;
 
    with 'Dist::Zilla::Role::PluginBundle::Merged' => {
       mv_plugins => [ qw( Plugin1 =Dist::Zilla::Bizarro::Foobar Plugin2 ) ],
    };
 
    sub configure {
       my $self = shift;
       $self->add_merged(
          qw( Plugin1 @Bundle1 =Dist::Zilla::Bizarro::Foobar ),
          {},  # force no options on the following plugins
          qw( ArglessPlugin1 ArglessPlugin2 ),
          $self->config_rename(plugin_dupearg => 'dupearg', removearg => undef),
          qw( Plugin2 ),
          $self->config_short_merge(['Plugin3', 'Plugin4'], { defaultarg => 1 }),
       );
    }

=head1 DESCRIPTION

This is a PluginBundle role, based partially on the underlying code from L<Dist::Zilla::PluginBundle::Git>.
As you can see from the example above, it's incredibly easy to make a bundle from this role.  It uses
L<Dist::Zilla::Role::PluginBundle::Easy>, so you have access to those same methods.

=head1 METHODS

=head2 add_merged

The C<<< add_merged >>> method takes a list (not arrayref) of plugin names, bundle names (with the C<<< @ >>>
prefix), or full module names (with the C<<< = >>> prefix).  This method combines C<<< add_plugins >>> & C<<< add_bundle >>>,
and handles all of the payload merging for you.  For example, if your bundle is passed the following
options:

    [@Bundle]
    arg1 = blah
    arg2 = foobar

Then it will pass the C<<< arg1/arg2 >>> options to each of the plugins, B<IF> they support the option.
Specifically, it does a C<<< $class->can($arg) >>> check.  (Bundles are passed the entire payload set.)  If
C<<< arg1 >>> exists for multiple plugins, it will pass the same option to all of them.  If you need separate
options, you should consider using the C<<< config_rename >>> method.

It will also accept hashrefs anywhere in the list, which will replace the payload arguments while
it processes.  This is useful for changing the options "on-the-fly" as plugins get processed.  The
replacement is done in order, and the changes will persist until it reaches the end of the list, or
receives another replacement.

If passed an arrayref, it will be directly passed to add_plugins.  Useful for plugins that use BUILDARGS
or some other non-standard configuration setup.

=head2 config_rename

This method is sort of like the L<config_slice|Dist::Zilla::Role::PluginBundle::Easy/config_slice> method,
but is more implicit than explicit.  It starts off with the entire payload (cloned), and renames any hash
pair that was passed:

    my $hash = $self->config_rename(foobar_arg1 => 'arg1');

This example will change the argument C<<< foobar_arg1 >>> to C<<< arg1 >>>.  This is handy if you want to make a
specific option for the plugin "Foobar" that doesn't clash with C<<< arg1 >>> on plugin "Baz":

    $self->add_merged(
       'Baz',
       $self->config_rename(foobar_arg1 => 'arg1', killme => ''),
       'Foobar',
    );

Any destination options are replaced.  Also, if the destination value is undef (or non-true), the key will
simply be deleted.  Keep in mind that this is all a clone of the payload, so extra calls to this method
will still start out with the original payload.

=head2 config_short_merge

Like C<<< config_rename >>>, this is meant to be used within an C<<< add_merged >>> block.  It takes either a single
plugin (scalar) or multiple ones (arrayref) as the first parameter, and a hashref of argumentE<sol>value pairs
as the second one.  This will merge in your own argumentE<sol>value pairs to the existing payload, pass the
module list, and then pass the original payload back.  For example:

    $self->add_merged(
       $self->config_short_merge(['Baz', 'Foobar'], { arg1 => 1 }),  # these two plugins have payload + arg1
       'Boom',  # only has the original payload
    );

Furthermore, the argument hash is expanded prior to the payload, so they can be overwritten by the payload.
Think of this as default arguments to pass to the plugins.

=head1 ROLE PARAMETERS

=head2 mv_plugins

Certain configuration parameters are "multi-value" ones (or MVPs), and L<Config::MVP> uses the
C<<< mvp_multivalue_args >>> sub in each class to identify which ones exist.  Since you are trying to merge the
configuration parameters of multiple plugins, you'll need to make sure your new plugin bundle identifies those
same MVPs.

Because the INI reader is closer to the beginning of the DZ plugin process, it would be too late for
C<<< add_merged >>> to start adding in keys to your C<<< mvp_multivalue_args >>> array.  Thus, this role is parameterized
with this single parameter, and comes with its own C<<< mvp_multivalue_args >>> method.  The syntax is a single
arrayref of strings in the same prefix structure as C<<< add_merged >>>.  For example:

    with 'Dist::Zilla::Role::PluginBundle::Merged' => {
       mv_plugins => [ qw( Plugin1 Plugin2 ) ],
    };

The above will identify these two plugins has having MVPs.  When L<Config::MVP> calls your C<<< mvp_multivalue_args >>>
sub (which is built into this role), it will load these two plugin classes and populate the contents
of B<their> C<<< mvp_multivalue_args >>> sub as a combined list to pass over to L<Config::MVP>.  In other words,
as long as you identify all of the plugins that would have multiple values, your stuff "just works".

If you need to identify any extra parameters as MVPs (like your own custom MVPs or "dupe preventing" parameters
that happen to be MVPs), you should consider combining C<<< mv_plugins >>> with an C<<< after mvp_multivalue_args >>> sub.

=head1 SUMMARY OF PARAMETERS

Here are all of the different options you can pass to C<<< add_merged >>>:

    $self->add_merged(
       ### SCALARs ###
       # These are all passed to add_plugins with an implicit payload
       'Plugin',
       '@PluginBundle',
       '=Dist::Zilla::Bizarro::Plugin',  # explicit class of plugin
 
       ### ARRAYs ###
       # These are all passed to add_plugins with an explicit payload
       ['Plugin'],
       ['Plugin', 'NewName'],
       ['Plugin', \%new_payload ],
       ['Plugin', 'NewName', \%new_payload ],
 
       ### HASHs ###
       {},              # force no options until reset
       $self->payload,  # reset to original payload
       \%new_payload,   # only pass those arg/value pairs as the payload
 
       $self->config_slice(qw( arg1 arg2 )),                    # only pass those args -from- the payload
       $self->config_slice('arg1', { foobar_arg2 => 'arg2' }),  # only pass those args -from- the payload (with arg renaming)
 
       $self->config_rename(foobar_arg1 => 'arg1'),             # rename args in the payload (and pass everything else)
       $self->config_rename(killme => ''),                      # remove args in the payload (and pass everything else)
 
       ### Combinations ###
       $self->config_short_merge('Plugin', \%add_on_payload),   # add args to the payload, pass to Plugin, and reset to original
       $self->config_short_merge(
          [ qw( Plugin1 Plugin2 ) ],    # add args to the payload, pass to plugin list, and reset to original payload
          \%add_on_payload
       ),
    );

=head1 CAVEATS

=over

=item *

Plugins that use non-standard payload methods will not be passed their options via C<<< add_merged >>>, unless passed
an arrayref to C<<< add_merged >>> with an specific payload.  The C<<< config_merge >>> method will warn you of this, because
it knows that you really want to use that argument.  Others will not.

=back

=over

=item *

Doing things more implicitly grants greater flexibility while sacrificing control.  YMMV.

=back

=head1 AVAILABILITY

The project homepage is L<https://github.com/SineSwiper/Dist-Zilla-Role-PluginBundle-Merged/wiki>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Dist::Zilla::Role::PluginBundle::Merged/>.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Internet Relay Chat

You can get live help by using IRC ( Internet Relay Chat ). If you don't know what IRC is,
please read this excellent guide: L<http://en.wikipedia.org/wiki/Internet_Relay_Chat>. Please
be courteous and patient when talking to us, as we might be busy or sleeping! You can join
those networks/channels and get help:

=over 4

=item *

irc.perl.org

You can connect to the server at 'irc.perl.org' and talk to this person for help: SineSwiper.

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests via L<https://github.com/SineSwiper/Dist-Zilla-Role-PluginBundle-Merged/issues>.

=head1 AUTHOR

Brendan Byrd <bbyrd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Brendan Byrd.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
