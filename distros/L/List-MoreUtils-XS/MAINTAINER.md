# Maintainers Guide for List::MoreUtils::XS

List::MoreUtils and List::MoreUtils::XS have common submodules to share
eg. tests. That's why it is a bit more complicated to setup a clone for
hacking on the beast.

# Get what you need

At first one need to clone the project and all it's submodules:

  $ git clone --recurse-submodules https://github.com/perl5-utils/List-MoreUtils-XS.git

# Prepare environment for configure stage

Then some (typically bundled) modules are required for Makefile.PL itself:

  $ cpanm --with-recommends --with-suggests Test::WriteVariants Config::AutoConf Carp inc::latest JSON::PP

# Start working

The typical workflow for authoring modules with ExtUtils::MakeMaker...

  $ cpanm --with-recommends --with-suggests --with-develop --installdeps .
  $ perl Makefile.PL
  $ make manifest
  $ make test

# Submitting contributions

When submitting patches or proposals or ideas or whatever - you realize and
agree the copyright and license conditions. Do not submit anything when you
don't agree on that.

# Copyright and License

All code added with 0.417 or later is licensed under the Apache License,
Version 2.0 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

All code until 0.416 is licensed under the same terms as Perl itself,
either Perl version 5.8.4 or, at your option, any later version of
Perl 5 you may have available.
