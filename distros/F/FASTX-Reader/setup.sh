#!/bin/bash
#cd package
cpanm Dist::Zilla
dzil authordeps --missing | cpanm
dzil listdeps --missing | cpanm
