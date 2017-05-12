package Java::JCR::Jackrabbit;

use strict;
use warnings;

our $VERSION = '0.06';

use Carp;
use Java::JCR;

use base qw( Java::JCR::Base Java::JCR::Repository );

=head1 NAME

Java::JCR::Jackrabbit - Java::JCR connector for Jackrabbit

=head1 SYNOPSIS

  my $repository = Java::JCR::Jackrabbit->new;

  # Or if you'd like to be more specific:
  my $other_repository 
      = Java::JCR::Jackrabbit->new('other/repository.xml', 'other');

=head1 DESCRIPTION

This is a simple wrapper for C<org.apache.jackrabbit.core.TransientRepository>. This creates a transient Jackrabbit repository using this class. To learn more about this class, see the Jackrabbit documentation:

  http://jackrabbit.apache.org/
  http://jackrabbit.apache.org/api-1/org/apache/jackrabbit/core/TransientRepository.html

=head2 ACCESSING A JACKRABBIT REPOSITORY

This package provides a C<new> method, which returns a repository object that's ready to use. There are two forms for using C<new>:

=over

=item 1.

With no arguments, Jackrabbit builds a repository using default values. It will construct a Derby-based repository in the local file system using a repository directory named F<repository> within the current working directory. It will also create a default repository configuration file in the current directory named F<repository.xml>. 

  my $repository = Java::JCR::Jackrabbit->new;

This is the fastest and easiest way to get started. However, the Derby database is written in Java and isn't very fast. It's great for quickly getting started, but I wouldn't recommend it for most production environments.

You can use this version of the constructor, but create a file named F<repository.xml> before performing the first login to the database. See the Jackrabbit documentation for more information on how to build such a configuration file.

=item 2.

The second form requires exactly two arguments to the C<new> method. The first is the name of the configuration file to use and the second is the directory to use as the repository home directory. This can be used to connect to repositories named something different or not in the current working directory. 

  my $repository = Java::JCR::Jackrabbit->new('config.xml', 'jackrabbit');

If the repository doesn't exist, the same action as happens for the first form happens, Jackrabbit creates a generic configuration and directory for storing a Derby-based database, but using the file and directory names you specify instead of F<repository.xml> and F<repository>.

You can customize the configuration as suggested above as well.

=back

=head2 CUSTOM NODE TYPES

There is an additional method provided by this package that allows your Perl program to register custom node types with Jackrabbit.

The JCR (as of JSR 170) does not specify a mechanism for creating custom node types. Therefore, use the C<register_node_types()> method, to do so:

  my $repository = Java::JCR::Jackrabbit->new;
  my $session = $repository->login(
          Java::JCR::SimpleCredentials->new('system', 'secret')
  );

  Java::JCR::Jackrabbit->register_node_types($session, 'nodetypes.cnd');

The C<register_nodetypes()> method takes two arguments:

=over

=item 1. 

The first argument is the session object to use to register the node types. This should be a session that has permission to create node types.

=item 2.

The second argument is the file name of a file formatted according to the Compact Namespace and Node Type Definition (CND) format used by Jackrabbit (see L<http://jackrabbit.apache.org/doc/nodetype/cnd.html>).

=back

After this method returns, all the custom node types found in the given CND file should be registered with Jackrabbit.

Here are a few additional cautionary notes you should consider when using this method:

=over

=item *

This implementation registers any non-reserved namespace found in the CND file that isn't already registered. It assumes that a registered prefix is mapped to the correct URI and doesn't do anything to verify whether this is actually true.

=item *

This implementation registers any nodetype found in the CND file that isn't already registered. It assumes that a registered node type hasn't changed and does nothing to check to see if this is actually true.

=back

This code is very basic and is only intended to let you get your nodetypes registered with a minimum of fuss. If you more complex handling of node type or namespace registration, you should write your own Java code to do so. 

If you want that code to be accessible from Perl and are not sure where to get started or just need something to start with, see the source of the L<Java::JCR::Jackrabbit> package. The Java class used to perform namespace and node type registration is defined within this package. This code was originally taken from the Jackrabbit documentation and modified to make it work here.

=cut

use Inline (
    Java => <<END_OF_JAVA,

import java.io.FileNotFoundException;
import java.io.FileReader;
import java.util.Collections;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import javax.jcr.NamespaceException;
import javax.jcr.NamespaceRegistry;
import javax.jcr.RepositoryException;
import javax.jcr.Session;
import javax.jcr.Workspace;

import org.apache.jackrabbit.core.nodetype.InvalidNodeTypeDefException;
import org.apache.jackrabbit.core.nodetype.NodeTypeDef;
import org.apache.jackrabbit.core.nodetype.NodeTypeManagerImpl;
import org.apache.jackrabbit.core.nodetype.NodeTypeRegistry;
import org.apache.jackrabbit.core.nodetype.compact.CompactNodeTypeDefReader;
import org.apache.jackrabbit.core.nodetype.compact.ParseException;

// The following code was adapted from the example on the Jackrabbit web site:
//
//    http://jackrabbit.apache.org/doc/nodetype/index.html (June 25, 2006)
//
class JackrabbitCustomNodeTypeRegistrar {
    public static final Map reserved;

    static {
        Map t = new HashMap();
        t.put("jcr", "http://www.jcp.org/jcr/1.0");
        t.put("nt", "http://www.jcp.org/jcr/nt/1.0");
        t.put("mix", "http://www.jcp.org/jcr/mix/1.0");
        t.put("xml", "http://www.w3.org/XML/1998/namespace");
        t.put("", "");
        reserved = Collections.unmodifiableMap(t);
    }

    public static void registerNodeTypes(Session session, 
            String cndFileName) throws FileNotFoundException, ParseException,
            RepositoryException, InvalidNodeTypeDefException {

        // Read in the CND file
        FileReader fileReader = new FileReader(cndFileName);

        // Create a CompactNodeTypeDefReader
        CompactNodeTypeDefReader cndReader
                = new CompactNodeTypeDefReader(fileReader, cndFileName);

        // Get the namespaces list of NodeTypeDef objects
        Map nsMap    = cndReader.getNamespaceMapping().getPrefixToURIMapping();
        List ntdList = cndReader.getNodeTypeDefs();

        // Get the workspace
        Workspace workspace = session.getWorkspace();

        // Get the namespace registry
        NamespaceRegistry nsReg = workspace.getNamespaceRegistry();

        // Get the Jackrabbit node type manager
        NodeTypeManagerImpl ntMgr 
            = (NodeTypeManagerImpl) workspace.getNodeTypeManager();

        // Acquire the NodeTypeRegistry
        NodeTypeRegistry ntReg = ntMgr.getNodeTypeRegistry();

        // Loop through the namespaces in the map and register each
        for (Iterator i = nsMap.entrySet().iterator(); i.hasNext();) {
            Map.Entry pair = (Map.Entry) i.next();
            String prefix = (String) pair.getKey();
            String uri = (String) pair.getValue();

            // Don't register the reserved prefixes or namespaces
            if (reserved.containsKey(prefix) || reserved.containsValue(uri)) {
                continue;
            }
            
            try {
                nsReg.getURI(prefix);
            }

            // If an exception is thrown, the prefix is unmapped
            catch (NamespaceException e) {
                nsReg.registerNamespace(prefix, uri);
            }
        }

        // Loop through the prepared NodeTypeDefs
        for (Iterator i = ntdList.iterator(); i.hasNext();) {

            // Get the NodeTypeDef...
            NodeTypeDef ntDef = (NodeTypeDef) i.next();

            // ...and register it, if it isn't already registered
            if (!ntReg.isRegistered(ntDef.getName())) {
                ntReg.registerNodeType(ntDef);
            }
        }
    }
}

END_OF_JAVA
    PACKAGE => 'Java::JCR',
    STUDY   => [],
);
use Inline::Java qw( study_classes );

study_classes(['org.apache.jackrabbit.core.TransientRepository'], 'Java::JCR');

sub new {
    my $class = shift;

    my $result = eval {
        bless {
            obj => Java::JCR::org::apache::jackrabbit::core::TransientRepository
                    ->new(@_),
        }, $class;
    };

    if ($@) {
        my $e = Java::JCR::Exception->new($@);
        croak $e;
    }

    return $result;
}

sub register_node_types {
    my ($class, $session, $cnd) = @_;

    eval {
        Java::JCR::JackrabbitCustomNodeTypeRegistrar->registerNodeTypes(
            $session->{obj}, $cnd
        );
    };

    if ($@) {
        my $e = Java::JCR::Exception->new($@);
        croak $e;
    }
}

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
