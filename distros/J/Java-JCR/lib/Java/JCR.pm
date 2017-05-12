package Java::JCR;

use strict;
use warnings;

use Carp;
use File::Spec;

our $VERSION = '0.08';

=head1 NAME

Java::JCR - Use JSR 170 (JCR) repositories from Perl

=head1 SYNOPSIS

  use Java::JCR;
  use Java::JCR::Jackrabbit;

  my $repository = Java::JCR::Jackrabbit->new;
  my $session = $repository->login(
      Java::JCR::SimpleCredentials->new('username', 'password')
  );

  my $root = $session->get_root_node;
  my $node = $root->add_node('foo', 'nt:unstructured');
  $node->set_property('bar', 10);
  $node->set_property('baz', 'blah');
  $node->set_property('qux', 4.8');
  $session->save;

=head1 DESCRIPTION

The JSR 170 specification describes a Java-based API for access hierarchical databases. This is generally referred to by the abbreviation JCR, which is an abbreviation for Content Repository API for Java Technology Specification.

The biggest OSS implementation, as of this writing, is Jackrabbit, which is a project at the Apache Software Foundation, L<http://jackrabbit.apache.org/>. Currently, this library allows Perl programmers to develop using the JCR and Jackrabbit, though, there's no reason why connectors can't be written for other implementations, such as Jaceira, CRX, eXoplatform, etc. The JCR library wrappers included are not at all specific to Jackrabbit. 

=head1 JAVA DOCUMENTATION

At this time, this library does not have documentation for any of the methods used. However, the Perl documentation included with each package links to the Java documentation for that package. That documentation can be used with this API by keeping the following in mind:

=over

=item *

Each C<javax.jcr.*> package is mapped into the C<Java::JCR::*> namespace using Perl-style package names.

=item *

By loading the parent package, you load all nested packages. That is, by loading this package, L<Java::JCR>, you load every immediate sub-package under L<Java::JCR>, such as L<Java::JCR::Repository>, L<Java::JCR::Session>, and L<Java::JCR::Node>.

If you want to access classes in one of the other packages, just load the parent. For example, if you want to load all the JCR classes, you need these bit of code:

  use Java::JCR;
  use Java::JCR::Lock;
  use Java::JCR::Nodetype; # <!-- N.B. letter case is a little funny here
  use Java::JCR::Observation;
  use Java::JCR::Query;
  use Java::JCR::Util;
  use Java::JCR::Version;

  # And the Jackrabbit connector:
  use Java::JCR::Jackrabbit;

=item *

All Java method names, which are in camel-case (theyHaveHumpsInTheMiddle), have been translated to use the more common (in Perl) lower-case with underscores. 

Thus, the following snippet in Java:

  Session session = repository.login();
  Node root = session.getRootNode();
  Node node = root.getNode("some/node/in/the/tree");
  Property property = node.getProperty("myProperty");

becomes this iin Perl:

  my $session = $repository->login;
  my $root = $session->get_root_node;
  my $node = $root->get_node("some/node/in/the/tree");
  my $property = $node->get_property("myProperty");

this includes abbreviations as well, so C<importXML()> and <getNodeByUUID()> in Java are C<import_xml()> and C<get_node_by_uuid()> in Perl.

=back

=head1 IMPLEMENTATION

Here's my opportunity to plug L<Inline::Java>. It works very well and made this possible. There are some deficiencies in exception handling and other places that one would expect difficulties, but all-in-all it works very well. The actual mapping to Java is done through this facility.

In addition, I've created a pure-Perl wrapper object for each to allow me to easily cope with problems in the mappings and to provide an opportunity to hook in better features. 

For example, the Java Date object isn't really an ideal solution for Perl coders. Therefore, it is planned that dates be mapped to a Perl equivalent (probably with the option of choosing your favorite since there are quite a few to choose from). This wouldn't be possible if the mapping was just the raw L<Inline::Java> one.

The wrappers also help smooth off some of the rough edges of the mapping from Java.

=cut

# Setup the Java Classpath
my $classpath;
BEGIN {
    my @classpath;
    my $this_path = $INC{'Java/JCR.pm'};
    $this_path =~ s/\.pm$//;
    my $jar_glob = File::Spec->catfile($this_path, "*.jar");
    for my $jar_file (glob $jar_glob) {
        push @classpath, $jar_file;
    }
    $classpath = join ':', @classpath, ($ENV{'CLASSPATH'} || '');
    $ENV{'CLASSPATH'} = $classpath;
}

use Inline (
    Java => <<'END_OF_JAVA',

class PerlUtils {
    public static char[] charArray(String str) {
        return str.toCharArray();
    }
}

END_OF_JAVA
    STUDY => [],
    CLASSPATH => $classpath,
);

sub import_my_packages {
    my ($package_name, $package_file) = caller;
    my %excludes = map { $_ => 1 } @_;

    my $package_dir = $package_file;
    $package_dir =~ s/\.pm$//;
    my $package_glob = File::Spec->catfile($package_dir, '*.pm');

    for my $package (glob $package_glob) {
        $package =~ s/^$package_dir\///;
        $package =~ s/\.pm$//;
        $package =~ s/\//::/g;

        next if $excludes{$package};

        eval "use ${package_name}::$package;";
        if ($@) { carp "Error loading $package: $@" }
    }
}

import_my_packages( 
    qw(
        Lock
        Nodetype
        Observation
        Query
        Util
        Version
    )
);

=head1 BUGS

Some things don't work. As of this writing, this is the first release, and I've only done just enough to get the first three "hops" from the Jackrabbit documentation going. You should be able to connect to a repository, login, get nodes and properties by path, create nodes and properties, and import XML using the examples on the Jackrabbit web site. (Perl ports of those are in the F<ex/> directory of the distribution, by the way.)

If you would like to contribute, let me know of a bug, or make a comment, please send me email at E<lt>hanenkamp@@cpan.orgE<gt> or post a ticket to CPAN RT at L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Java-JCR>.

=head1 SEE ALSO

L<http://www.jcp.org/en/jsr/detail?id=170>, L<http://www.day.com/maven/jsr170/javadocs/jcr-1.0/>, L<Inline::Java>, L<Java::JCR::Lock>, L<Java::JCR::Nodetype>, L<Java::JCR::Observation>, L<Java::JCR::Query>, L<Java::JCR::Util>, L<Java::JCR::Version>, L<Java::JCR::Jackrabbit>

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2006 Andrew Sterling Hanenkamp E<lt>hanenkamp@cpan.orgE<gt>.  All 
Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.

=cut

1
