#!/bin/bash

perl -MDBIx::Class::Schema::Loader=make_schema_at,dump_to_dir:./lib -e 'make_schema_at("HPC::Runner::Command::Plugin::Logger::Sqlite::Schema", { debug => 1  }, [ "dbi:SQLite:dbname=./hpc-runner-command-plugin-logger-sqlite.db" ])'
