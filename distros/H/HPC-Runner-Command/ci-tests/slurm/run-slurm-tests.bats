#!/usr/bin/env bats

load ../test_helpers/helpers
load ../test_helpers/slurm

setup() {
    echo "This is the setup!"
    cd /hpc-runner-command
}

teardown() {
    rm -rf /tmp/hpc*
}

install_hpc_sqlite() {

	if [[ -z "${HPC_SQLITE_BRANCH}" ]] ; then
	    echo "NO HPC-Runner-Command-Plugin-Logger-Sqlite branch specified. Installing from master."
	    cpanm --quiet --notest git://github.com/jerowe/HPC-Runner-Command-Plugin-Logger-Sqlite.git@${HPC_SQLITE_BRANCH}
	else
	    echo "Installing HPC-Runner-Command-Plugin-Logger-Sqlite from develop"
	    cpanm --quiet --notest git://github.com/jerowe/HPC-Runner-Command-Plugin-Logger-Sqlite.git@${HPC_SQLITE_BRANCH}
	fi
}

@test "001 install hpc-runner-command libraries" {

	run sh -c "cd /hpc-runner-command"
	run sh -c "milla build"
	assert_success
	run sh -c "milla test"
	assert_success
	run sh -c "milla install"
	assert_success

}

@test "002 install hpc-runner-command-plugin-logger-sqlite libraries " {

	install_hpc_sqlite
	assert_success

}

@test "003 test simple " {

	run sh -c "rm -rf $TESTDIR"
	run sh -c "mkdir -p $TESTDIR"
	run sh -c "cp ${BASE_DIR}/test001-simple.submit ${TESTDIR}"
	assert_success

	run sh -c "cd $TESTDIR && hpcrunner.pl submit_jobs --infile test001-simple.submit --hpc_plugins Slurm,Logger::Sqlite --hpc_plugins_opts cleandb=1"
	echo "output: "$output
	echo "status: "$status
	assert_success
	run sh -c "cd $TESTDIR && hpcrunner.pl watch_db --plugins Logger::Sqlite --plugins_opts submission_id=1"
	echo "output: "$output
	echo "status: "$status
	assert_success

	run sh -c "cd $BASE_DIR"
	run sh -c "rm -rf $TESTDIR"
	assert_success
}

@test "004 test linear deps" {

	run sh -c "rm -rf $TESTDIR"
	run sh -c "mkdir -p $TESTDIR"
	assert_success
	run sh -c "cp ${BASE_DIR}/test002-lineardeps.submit $TESTDIR"

	run sh -c "cd $TESTDIR && hpcrunner.pl submit_jobs --infile test002-lineardeps.submit --hpc_plugins Slurm,Logger::Sqlite --hpc_plugins_opts cleandb=1"
	echo "output: "$output
	echo "status: "$status
	assert_success
	run sh -c "cd $TESTDIR && time hpcrunner.pl watch_db --plugins Logger::Sqlite --plugins_opts submission_id=1"
	echo "output: "$output
	echo "status: "$status
	assert_success

	run sh -c "cd $BASE_DIR"
	run sh -c "rm -rf $TESTDIR"
	assert_success
}

@test "005 test non linear deps" {

	run sh -c "rm -rf $TESTDIR"
	run sh -c "mkdir -p $TESTDIR"
	run sh -c "cp ${BASE_DIR}/test003-non_lineardeps.submit $TESTDIR"
	assert_success

	run sh -c "cd $TESTDIR"
	assert_success

	run sh -c "cd $TESTDIR && hpcrunner.pl submit_jobs --infile test003-non_lineardeps.submit --hpc_plugins Slurm,Logger::Sqlite --hpc_plugins_opts cleandb=1"
	echo "output: "$output
	echo "status: "$status
	assert_success
	run sh -c "cd $TESTDIR && time hpcrunner.pl watch_db  --plugins Logger::Sqlite --plugins_opts submission_id=1"
	echo "output: "$output
	echo "status: "$status
	assert_success

	run sh -c "cd $BASE_DIR"
	run sh -c "rm -rf $TESTDIR"
	assert_success
}
