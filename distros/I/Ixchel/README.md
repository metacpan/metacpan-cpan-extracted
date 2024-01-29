# Ixchel

!!!WARNING!!! Very much a work in progress and testing at this stage. !!!WARNING!!!

Configuration and templating system meant to be used Ansible or
Rex. Config generated centeral and pushed out and templating/actions
done based on that on the remote systems for purpose of continual
integration pipe line for server configuration as well as setup.

## Setup

### CMDB Setup

First you will want to get a CMDB setup using like
[Shell:Var::Reader](https://github.com/VVelox/Shell-Var-Reader)
([CPAN](https://metacpan.org/dist/Shell-Var-Reader)).

This will make it easy to create easy to create the config
used by Ixchel as well as config files that can easily be shared
with other things.

Once you have everything setup and `cmdb_shell_var_reader`
working, you are ready to move on to the next step.

### Integration With Tooling

#### Rex

```
use Rex -feature => ['1.4'];
use File::Slurp;

group all => 'a.foo.bar', 'b.foo.bar;

set cmdb => {
              type           => 'TOML',
              path           => ./cmdb/,
              merge_behavior => 'LEFT_PRECEDENT',
              use_roles      => 1,
            };

desc 'Upload Server Confs';
task 'upload_server_confs',
        group => all',
        sub {
                my $remote_hostname = connection->server;

                mkdir('/usr/local/etc/ixchel');

                my @types = ( 'toml', 'yaml', 'json', 'shell' );
                foreach my $type (@types) {
                        my $type_dir = $type;
                        if ( $type eq 'shell' ) {
                                $type = 'sh';
                        }
                        my $upload_from = $type_dir . '_confs/' . $remote_hostname . '.' . $type;
                        if ( -f $upload_from ) {
                                my $content=read_file($upload_from);
                                file '/usr/local/etc/ixchel/server.' . $type, content => $content;
                        }
                } ## end foreach my $type (@types)
        };
```

#### Ansible

```
- hosts: "{{ host }}"
  order: sorted
  gather_facts: false
  ignore_errors: true
  ignore_unreachable: true
  become: true
  become_method: sudo
  serial: 1

  tasks:
  - name: Copy System JSON Conf Into Place
    ansible.builtin.copy:
      src: ./json_confs/{{ inventory_hostname }}.json
      dest: /usr/local/etc/ixchel/server.json

  - name: Copy System Shell Conf Into Place
    ansible.builtin.copy:
      src: ./shell_confs/{{ inventory_hostname }}.conf
      dest: /usr/local/etc/ixchel/server.conf

  - name: Copy System YAML Conf Into Place
    ansible.builtin.copy:
      src: ./yaml_confs/{{ inventory_hostname }}.yaml
      dest: /usr/local/etc/ixchel/server.yaml

  - name: Copy System TOML Conf Into Place
    ansible.builtin.copy:
      src: ./toml_confs/{{ inventory_hostname }}.toml
      dest: /usr/local/etc/ixchel/server.toml
```

And if you wish to use the generated JSON config file with a system in
a Ansible task, it can be done like below.

```
- hosts: "{{ host }}"
  var_files:
    - ./json_confs/{{ inventory_hostname }}.json
```

#### Shell Scripts

If generating the configs via Shell::Var::Reader, the generated shell
conf file can easily be included in sh, zsh, and bash scripts like below.

```
. /usr/local/etc/ixchel/server.sh
```

That said it is worth nothing these do not include any of the default
variables for Ixchel. Only those that have been explicitely set via
the CMDB.

## Install

Perl modules needed.

- Config::Tiny
- Data::Dumper
- File::Find::Rule
- File::ShareDir
- File::Slurp
- Hash::Merge
- JSON
- JSON::Path
- LWP::Simple
- Module::List
- Rex
- String::ShellQuote
- TOML::Tiny
- Template
- YAML::XS

Other Libraries.

- libyaml

### Debian

1. `apt-get install libconfig-tiny-perl libfile-find-rule-perl
libfile-sharedir-perl libfile-slurp-perl libhash-merge-perl
libjson-perl libjson-path-perl libwww-perl rex
libstring-shellquote-perl libtemplate-perl
libyaml-libyaml-perl cpanminus`
2. `cpanm Ixchel`

### FreeBSD

1. `pkg intall p5-Config-Tiny p5-Data-Dumper p5-File-Find-Rule
p5-File-ShareDir p5-File-Slurp p5-Hash-Merge p5-JSON p5-JSON-Path
p5-libwww p5-Module-List p5-Rex p5-String-ShellQuote
p5-Template-Toolkit p5-YAML-LibYAML p5-App-cpanminus`
2. `cpanm Ixchel`

## TODO

- sub path selection for xeno when passing hashes
- Sagan config comparison
- add in file_cleaner_by_du support
- Apache config management(genearlized manner)
- actions for...
  - Lilith
	- install client
	- db server setup
  - CAPEv2
  - snmp setup
- better documentation for Suricata outputs
- use File::Spec->canonpath every where relevant
- lots more documentation
