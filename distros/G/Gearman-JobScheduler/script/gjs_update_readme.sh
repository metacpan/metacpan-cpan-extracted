#!/bin/bash

echo -n > README.mdown
echo "[![Build Status](https://travis-ci.org/pypt/p5-Gearman-JobScheduler.svg?branch=master)](https://travis-ci.org/pypt/p5-Gearman-JobScheduler)" >> README.mdown
echo >> README.mdown
pod2markdown lib/Gearman/JobScheduler/AbstractFunction.pm >> README.mdown
