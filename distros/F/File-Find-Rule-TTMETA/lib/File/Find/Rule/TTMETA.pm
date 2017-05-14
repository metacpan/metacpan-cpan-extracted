package File::Find::Rule::TTMETA;

use strict;
use vars qw($VERSION);
use base qw(File::Find::Rule);

use Template::Config;

my $provider;

sub File::Find::Rule::ttmeta {
    my $self = shift->_force_object();
    my $meta = UNIVERSAL::isa($_[0], 'HASH') ? shift : { @_ };

    $self->exec(
        sub {
            my $file = shift;
            my ($doc, $match, $key);
            $match = 0;

            # Optimization
            return $match
                if scalar keys %$meta == 0;

            # warn " *** $file ***\n";

            # Skip directories
            return if -d $file;

            # Set $provider to a Template::Provider instance or workalike
            # $file contains an absolute path
            $provider = Template::Config->provider(ABSOLUTE => 1)
                unless defined $provider;

            # Attempt to turn the file into a Template::Document instance,
            # or return -- it can't match if it isn't a valid Template.
            eval { ($doc) = $provider->fetch($file); };
            return if $@;

            # Bad Things Happened.  Next!
            return unless defined $doc &&
                UNIVERSAL::isa($doc, 'Template::Document');

            # The intent is to match all of the possibilities;
            # if someone specifies:
            #
            #   find(ttmeta => { AUTHOR => 'foo', VERSION => '1.1' })
            #
            # then we only want to return success if all match.
            #
            # To support complex (TT-style foo.bar) variables, $key 
            # would need to be split on /\./, and each element treated
            # as either a hash or array entry.  This reimplementing of
            # Template::Stash::_dotop bugs me, though.
            for $key (keys %$meta) {
                my $val = $meta->{$key};

                if (ref $val eq 'Regexp') {
                    $match++ if $doc->$key() =~ $val;
                }
                else {
                    $match++ if $doc->$key() eq $val;
                }
            }

            return $match == scalar keys %$meta;
        }
    );
}

1;

__END__

=head1 NAME

File::Find::Rule::TTMETA - Find files based on Template Toolkit META directives

=head1 SYNOPSIS

    use File::Find::Rule qw(:TTMETA);

    my @files = find(ttmeta => { author => "darren chamberlain" },
                     in => "/var/www/html");

=head1 DESCRIPTION

C<File::Find::Rule::TTMETA> extends C<File::Find::Rule> to work with
Template Toolkit templates by providing access to template-specific
metadata.

C<File::Find::Rule::TTMETA> adds a C<ttmeta> method / keyword to
C<File::Find::Rule>.  C<ttmeta> takes a series of name, value
tuples, each of which is compared to the metadata for the file in
question (a C<Template::Provider> instance attempts to treat each file
as a template; compile errors are silently skipped).  A file matches
if I<each> element of metadata defined in C<ttmeta> is present.  If
there are multiple keys defined, all must match for the file to be
considered a match.

Values can be strings or regexes:

    find(ttmeta => { VERSION => qr/^2\.\d+/ } => in => $dir);

    File::Find::Rule->file
                    ->ttmeta(color => "green", sheep => 3)
                    ->in($dir);

More complex variables are not (currently) supported by this module,
even though C<Template::Document> supports them.  Patches welcome.

=head1 Template Toolkit DETAILS

C<File::Find::Rule::TTMETA> uses C<Template::Config> to
instantiate its C<Template::Provider> instance, so it is possible
to use custom provider subclasses.

The C<Template::Provider> instance that is created has only C<ABSOLUTE
=E<gt> 1> set, mainly because most of the other options don't really
apply here, but also because I can't think of an elegant way to pass
configuration parameters to the constructor.

=head1 SEE ALSO

L<File::Find::Rule>, L<Template>
