#!/usr/bin/perl -w

# $Id: --- $
# Created by Ingo Lantschner on 2009-06-24.
# Copyright (c) 2009 Ingo Lantschner. All rights reserved.
# perl[at]lantschner.name, http://ingo@lantschner.name

use warnings;
use strict;

# Test for Waypoints, which are slightly outside of the bounding-box

# Debugging
our $DEBUG = 0;
#use Smart::Comments '###';

use Test::More  'no_plan';
use Data::Dumper;

use Gpx::Addons::Filter qw( filter_trk filter_wp first_and_last_second_of);
use Geo::Gpx;

(my  $gpx_test_file = << "END_HERE") =~ s/^\s+//gm;
    <?xml version="1.0" encoding="utf-8"?>
    <gpx xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="1.1" creator="Geo::Gpx" xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd" xmlns="http://www.topografix.com/GPX/1/1">
    <metadata>
    <time>2009-08-16T07:40:40+00:00</time>
    <bounds maxlat="48.192113" maxlon="16.359187" minlat="48.006509" minlon="16.023388" />
    </metadata>
    <trk>
    <name>ACTIVE LOG: 15 Aug 2009 11:15</name>
    <trkseg>
    <trkpt lat="48.192113" lon="16.348712">
    <ele>207.30</ele>
    <time>2009-08-15T09:15:28+00:00</time>
    </trkpt>
    <trkpt lat="48.192073" lon="16.348541">
    <ele>177.02</ele>
    <time>2009-08-15T09:15:33+00:00</time>
    </trkpt>
    <trkpt lat="48.191747" lon="16.348880">
    <ele>97.71</ele>
    <time>2009-08-15T09:15:48+00:00</time>
    </trkpt>
    <trkpt lat="48.191716" lon="16.348933">
    <ele>95.79</ele>
    <time>2009-08-15T09:15:49+00:00</time>
    </trkpt>
    <trkpt lat="48.191678" lon="16.348995">
    <ele>93.87</ele>
    <time>2009-08-15T09:15:50+00:00</time>
    </trkpt>
    <trkpt lat="48.191595" lon="16.349134">
    <ele>91.94</ele>
    <time>2009-08-15T09:15:52+00:00</time>
    </trkpt>
    <trkpt lat="48.191552" lon="16.349206">
    <ele>90.50</ele>
    <time>2009-08-15T09:15:53+00:00</time>
    </trkpt>
    <trkpt lat="48.191214" lon="16.349738">
    <ele>74.64</ele>
    <time>2009-08-15T09:16:00+00:00</time>
    </trkpt>
    <trkpt lat="48.191162" lon="16.349817">
    <ele>73.20</ele>
    <time>2009-08-15T09:16:01+00:00</time>
    </trkpt>
    <trkpt lat="48.191109" lon="16.349896">
    <ele>71.76</ele>
    <time>2009-08-15T09:16:02+00:00</time>
    </trkpt>
    <trkpt lat="48.191016" lon="16.350025">
    <ele>73.68</ele>
    <time>2009-08-15T09:16:04+00:00</time>
    </trkpt>
    <trkpt lat="48.190955" lon="16.350101">
    <ele>79.45</ele>
    <time>2009-08-15T09:16:05+00:00</time>
    </trkpt>
    <trkpt lat="48.190910" lon="16.350157">
    <ele>83.77</ele>
    <time>2009-08-15T09:16:06+00:00</time>
    </trkpt>
    <trkpt lat="48.190882" lon="16.350192">
    <ele>87.62</ele>
    <time>2009-08-15T09:16:07+00:00</time>
    </trkpt>
    <trkpt lat="48.190721" lon="16.350393">
    <ele>140.97</ele>
    <time>2009-08-15T09:16:15+00:00</time>
    </trkpt>
    <trkpt lat="48.190705" lon="16.350414">
    <ele>141.93</ele>
    <time>2009-08-15T09:16:16+00:00</time>
    </trkpt>
    <trkpt lat="48.190674" lon="16.350452">
    <ele>142.41</ele>
    <time>2009-08-15T09:16:17+00:00</time>
    </trkpt>
    <trkpt lat="48.190627" lon="16.350511">
    <ele>142.89</ele>
    <time>2009-08-15T09:16:18+00:00</time>
    </trkpt>
    <trkpt lat="48.190519" lon="16.350646">
    <ele>143.37</ele>
    <time>2009-08-15T09:16:19+00:00</time>
    </trkpt>
    <trkpt lat="48.189560" lon="16.351258">
    <ele>154.43</ele>
    <time>2009-08-15T09:16:29+00:00</time>
    </trkpt>
    <trkpt lat="48.188843" lon="16.351617">
    <ele>157.79</ele>
    <time>2009-08-15T09:16:37+00:00</time>
    </trkpt>
    <trkpt lat="48.187676" lon="16.352215">
    <ele>164.04</ele>
    <time>2009-08-15T09:16:48+00:00</time>
    </trkpt>
    <trkpt lat="48.187010" lon="16.352741">
    <ele>168.37</ele>
    <time>2009-08-15T09:16:56+00:00</time>
    </trkpt>
    <trkpt lat="48.186953" lon="16.352790">
    <ele>168.85</ele>
    <time>2009-08-15T09:16:57+00:00</time>
    </trkpt>
    <trkpt lat="48.186809" lon="16.352934">
    <ele>172.69</ele>
    <time>2009-08-15T09:17:04+00:00</time>
    </trkpt>
    <trkpt lat="48.186580" lon="16.353163">
    <ele>182.79</ele>
    <time>2009-08-15T09:17:20+00:00</time>
    </trkpt>
    <trkpt lat="48.186518" lon="16.353222">
    <ele>182.79</ele>
    <time>2009-08-15T09:17:21+00:00</time>
    </trkpt>
    <trkpt lat="48.186460" lon="16.353273">
    <ele>183.27</ele>
    <time>2009-08-15T09:17:22+00:00</time>
    </trkpt>
    <trkpt lat="48.186356" lon="16.353367">
    <ele>183.27</ele>
    <time>2009-08-15T09:17:24+00:00</time>
    </trkpt>
    <trkpt lat="48.185680" lon="16.353980">
    <ele>184.71</ele>
    <time>2009-08-15T09:17:36+00:00</time>
    </trkpt>
    <trkpt lat="48.185399" lon="16.354275">
    <ele>183.75</ele>
    <time>2009-08-15T09:17:41+00:00</time>
    </trkpt>
    <trkpt lat="48.184672" lon="16.355028">
    <ele>181.35</ele>
    <time>2009-08-15T09:17:53+00:00</time>
    </trkpt>
    <trkpt lat="48.184355" lon="16.355345">
    <ele>182.31</ele>
    <time>2009-08-15T09:17:58+00:00</time>
    </trkpt>
    <trkpt lat="48.184247" lon="16.355454">
    <ele>182.31</ele>
    <time>2009-08-15T09:18:00+00:00</time>
    </trkpt>
    <trkpt lat="48.183985" lon="16.355716">
    <ele>183.27</ele>
    <time>2009-08-15T09:18:04+00:00</time>
    </trkpt>
    <trkpt lat="48.183032" lon="16.356712">
    <ele>185.67</ele>
    <time>2009-08-15T09:18:16+00:00</time>
    </trkpt>
    <trkpt lat="48.182037" lon="16.357749">
    <ele>193.36</ele>
    <time>2009-08-15T09:18:27+00:00</time>
    </trkpt>
    <trkpt lat="48.181601" lon="16.358185">
    <ele>210.19</ele>
    <time>2009-08-15T09:18:35+00:00</time>
    </trkpt>
    <trkpt lat="48.181601" lon="16.358185">
    <ele>211.63</ele>
    <time>2009-08-15T09:19:06+00:00</time>
    </trkpt>
    <trkpt lat="48.181350" lon="16.358436">
    <ele>210.67</ele>
    <time>2009-08-15T09:19:29+00:00</time>
    </trkpt>
    <trkpt lat="48.181286" lon="16.358500">
    <ele>211.15</ele>
    <time>2009-08-15T09:19:30+00:00</time>
    </trkpt>
    <trkpt lat="48.181286" lon="16.358500">
    <ele>211.15</ele>
    <time>2009-08-15T09:19:31+00:00</time>
    </trkpt>
    <trkpt lat="48.180398" lon="16.359097">
    <ele>213.07</ele>
    <time>2009-08-15T09:19:41+00:00</time>
    </trkpt>
    <trkpt lat="48.179960" lon="16.359187">
    <ele>214.03</ele>
    <time>2009-08-15T09:19:45+00:00</time>
    </trkpt>
    <trkpt lat="48.179870" lon="16.359169">
    <ele>214.03</ele>
    <time>2009-08-15T09:19:46+00:00</time>
    </trkpt>
    <trkpt lat="48.179809" lon="16.359154">
    <ele>214.51</ele>
    <time>2009-08-15T09:19:47+00:00</time>
    </trkpt>
    <trkpt lat="48.179748" lon="16.359106">
    <ele>214.51</ele>
    <time>2009-08-15T09:19:48+00:00</time>
    </trkpt>
    <trkpt lat="48.179688" lon="16.359057">
    <ele>214.51</ele>
    <time>2009-08-15T09:19:49+00:00</time>
    </trkpt>
    <trkpt lat="48.179607" lon="16.358993">
    <ele>214.03</ele>
    <time>2009-08-15T09:19:50+00:00</time>
    </trkpt>
    <trkpt lat="48.179522" lon="16.358914">
    <ele>213.55</ele>
    <time>2009-08-15T09:19:51+00:00</time>
    </trkpt>
    <trkpt lat="48.179428" lon="16.358825">
    <ele>213.07</ele>
    <time>2009-08-15T09:19:52+00:00</time>
    </trkpt>
    <trkpt lat="48.178301" lon="16.357763">
    <ele>215.95</ele>
    <time>2009-08-15T09:20:04+00:00</time>
    </trkpt>
    <trkpt lat="48.176903" lon="16.356420">
    <ele>220.28</ele>
    <time>2009-08-15T09:20:18+00:00</time>
    </trkpt>
    <trkpt lat="48.175086" lon="16.354694">
    <ele>227.49</ele>
    <time>2009-08-15T09:20:34+00:00</time>
    </trkpt>
    <trkpt lat="48.172926" lon="16.352625">
    <ele>239.51</ele>
    <time>2009-08-15T09:20:51+00:00</time>
    </trkpt>
    <trkpt lat="48.170845" lon="16.350706">
    <ele>249.60</ele>
    <time>2009-08-15T09:21:08+00:00</time>
    </trkpt>
    <trkpt lat="48.169041" lon="16.349529">
    <ele>253.44</ele>
    <time>2009-08-15T09:21:22+00:00</time>
    </trkpt>
    <trkpt lat="48.167014" lon="16.348238">
    <ele>248.64</ele>
    <time>2009-08-15T09:21:36+00:00</time>
    </trkpt>
    <trkpt lat="48.166147" lon="16.347701">
    <ele>244.31</ele>
    <time>2009-08-15T09:21:44+00:00</time>
    </trkpt>
    <trkpt lat="48.165995" lon="16.347607">
    <ele>241.91</ele>
    <time>2009-08-15T09:21:50+00:00</time>
    </trkpt>
    <trkpt lat="48.165728" lon="16.347410">
    <ele>240.95</ele>
    <time>2009-08-15T09:22:28+00:00</time>
    </trkpt>
    <trkpt lat="48.164977" lon="16.346925">
    <ele>238.06</ele>
    <time>2009-08-15T09:22:35+00:00</time>
    </trkpt>
    <trkpt lat="48.163318" lon="16.345904">
    <ele>231.81</ele>
    <time>2009-08-15T09:22:46+00:00</time>
    </trkpt>
    <trkpt lat="48.160493" lon="16.344034">
    <ele>219.80</ele>
    <time>2009-08-15T09:23:04+00:00</time>
    </trkpt>
    <trkpt lat="48.158346" lon="16.342497">
    <ele>208.26</ele>
    <time>2009-08-15T09:23:19+00:00</time>
    </trkpt>
    <trkpt lat="48.157977" lon="16.342228">
    <ele>205.38</ele>
    <time>2009-08-15T09:23:25+00:00</time>
    </trkpt>
    <trkpt lat="48.157306" lon="16.341751">
    <ele>202.98</ele>
    <time>2009-08-15T09:23:32+00:00</time>
    </trkpt>
    <trkpt lat="48.155691" lon="16.340534">
    <ele>200.09</ele>
    <time>2009-08-15T09:23:43+00:00</time>
    </trkpt>
    <trkpt lat="48.153681" lon="16.339100">
    <ele>198.17</ele>
    <time>2009-08-15T09:23:56+00:00</time>
    </trkpt>
    <trkpt lat="48.151919" lon="16.337693">
    <ele>196.73</ele>
    <time>2009-08-15T09:24:08+00:00</time>
    </trkpt>
    <trkpt lat="48.150507" lon="16.336715">
    <ele>197.21</ele>
    <time>2009-08-15T09:24:17+00:00</time>
    </trkpt>
    <trkpt lat="48.150346" lon="16.336702">
    <ele>197.69</ele>
    <time>2009-08-15T09:24:18+00:00</time>
    </trkpt>
    <trkpt lat="48.150183" lon="16.336690">
    <ele>198.17</ele>
    <time>2009-08-15T09:24:19+00:00</time>
    </trkpt>
    <trkpt lat="48.148651" lon="16.336643">
    <ele>203.94</ele>
    <time>2009-08-15T09:24:28+00:00</time>
    </trkpt>
    <trkpt lat="48.147059" lon="16.336069">
    <ele>205.38</ele>
    <time>2009-08-15T09:24:36+00:00</time>
    </trkpt>
    <trkpt lat="48.143640" lon="16.334588">
    <ele>204.42</ele>
    <time>2009-08-15T09:24:53+00:00</time>
    </trkpt>
    <trkpt lat="48.140662" lon="16.333313">
    <ele>204.42</ele>
    <time>2009-08-15T09:25:09+00:00</time>
    </trkpt>
    <trkpt lat="48.138152" lon="16.332239">
    <ele>205.38</ele>
    <time>2009-08-15T09:25:23+00:00</time>
    </trkpt>
    <trkpt lat="48.135920" lon="16.331273">
    <ele>209.22</ele>
    <time>2009-08-15T09:25:34+00:00</time>
    </trkpt>
    <trkpt lat="48.131951" lon="16.329556">
    <ele>213.07</ele>
    <time>2009-08-15T09:25:53+00:00</time>
    </trkpt>
    <trkpt lat="48.129158" lon="16.328347">
    <ele>214.51</ele>
    <time>2009-08-15T09:26:07+00:00</time>
    </trkpt>
    <trkpt lat="48.126881" lon="16.327345">
    <ele>216.43</ele>
    <time>2009-08-15T09:26:18+00:00</time>
    </trkpt>
    <trkpt lat="48.124427" lon="16.326101">
    <ele>218.36</ele>
    <time>2009-08-15T09:26:30+00:00</time>
    </trkpt>
    <trkpt lat="48.122512" lon="16.324849">
    <ele>220.28</ele>
    <time>2009-08-15T09:26:40+00:00</time>
    </trkpt>
    <trkpt lat="48.121613" lon="16.323354">
    <ele>224.12</ele>
    <time>2009-08-15T09:26:47+00:00</time>
    </trkpt>
    <trkpt lat="48.121199" lon="16.321752">
    <ele>228.45</ele>
    <time>2009-08-15T09:26:53+00:00</time>
    </trkpt>
    <trkpt lat="48.121120" lon="16.320012">
    <ele>232.30</ele>
    <time>2009-08-15T09:27:00+00:00</time>
    </trkpt>
    <trkpt lat="48.121330" lon="16.316691">
    <ele>230.85</ele>
    <time>2009-08-15T09:27:10+00:00</time>
    </trkpt>
    <trkpt lat="48.121638" lon="16.311967">
    <ele>227.49</ele>
    <time>2009-08-15T09:27:25+00:00</time>
    </trkpt>
    <trkpt lat="48.121245" lon="16.308474">
    <ele>224.61</ele>
    <time>2009-08-15T09:27:35+00:00</time>
    </trkpt>
    <trkpt lat="48.120383" lon="16.305590">
    <ele>222.68</ele>
    <time>2009-08-15T09:27:44+00:00</time>
    </trkpt>
    <trkpt lat="48.118120" lon="16.299487">
    <ele>220.28</ele>
    <time>2009-08-15T09:28:04+00:00</time>
    </trkpt>
    <trkpt lat="48.117118" lon="16.296353">
    <ele>219.32</ele>
    <time>2009-08-15T09:28:15+00:00</time>
    </trkpt>
    <trkpt lat="48.116413" lon="16.293023">
    <ele>224.12</ele>
    <time>2009-08-15T09:28:26+00:00</time>
    </trkpt>
    <trkpt lat="48.116081" lon="16.289494">
    <ele>231.81</ele>
    <time>2009-08-15T09:28:38+00:00</time>
    </trkpt>
    <trkpt lat="48.115648" lon="16.283590">
    <ele>239.51</ele>
    <time>2009-08-15T09:28:58+00:00</time>
    </trkpt>
    <trkpt lat="48.115033" lon="16.280962">
    <ele>241.91</ele>
    <time>2009-08-15T09:29:07+00:00</time>
    </trkpt>
    <trkpt lat="48.113918" lon="16.278400">
    <ele>245.27</ele>
    <time>2009-08-15T09:29:17+00:00</time>
    </trkpt>
    <trkpt lat="48.111830" lon="16.274724">
    <ele>253.93</ele>
    <time>2009-08-15T09:29:33+00:00</time>
    </trkpt>
    <trkpt lat="48.110944" lon="16.272431">
    <ele>263.06</ele>
    <time>2009-08-15T09:29:42+00:00</time>
    </trkpt>
    <trkpt lat="48.110419" lon="16.269690">
    <ele>275.56</ele>
    <time>2009-08-15T09:29:52+00:00</time>
    </trkpt>
    <trkpt lat="48.109981" lon="16.265545">
    <ele>293.34</ele>
    <time>2009-08-15T09:30:07+00:00</time>
    </trkpt>
    <trkpt lat="48.109294" lon="16.262865">
    <ele>304.88</ele>
    <time>2009-08-15T09:30:17+00:00</time>
    </trkpt>
    <trkpt lat="48.108109" lon="16.260537">
    <ele>316.41</ele>
    <time>2009-08-15T09:30:27+00:00</time>
    </trkpt>
    <trkpt lat="48.106676" lon="16.258838">
    <ele>326.99</ele>
    <time>2009-08-15T09:30:36+00:00</time>
    </trkpt>
    <trkpt lat="48.104671" lon="16.256808">
    <ele>338.52</ele>
    <time>2009-08-15T09:30:48+00:00</time>
    </trkpt>
    <trkpt lat="48.103442" lon="16.254819">
    <ele>346.21</ele>
    <time>2009-08-15T09:30:57+00:00</time>
    </trkpt>
    <trkpt lat="48.101639" lon="16.250696">
    <ele>361.59</ele>
    <time>2009-08-15T09:31:13+00:00</time>
    </trkpt>
    <trkpt lat="48.099095" lon="16.244733">
    <ele>388.03</ele>
    <time>2009-08-15T09:31:36+00:00</time>
    </trkpt>
    <trkpt lat="48.097318" lon="16.240606">
    <ele>405.81</ele>
    <time>2009-08-15T09:31:52+00:00</time>
    </trkpt>
    <trkpt lat="48.095962" lon="16.238500">
    <ele>413.02</ele>
    <time>2009-08-15T09:32:01+00:00</time>
    </trkpt>
    <trkpt lat="48.094431" lon="16.237071">
    <ele>417.35</ele>
    <time>2009-08-15T09:32:09+00:00</time>
    </trkpt>
    <trkpt lat="48.092113" lon="16.235731">
    <ele>422.16</ele>
    <time>2009-08-15T09:32:20+00:00</time>
    </trkpt>
    <trkpt lat="48.088793" lon="16.233851">
    <ele>421.68</ele>
    <time>2009-08-15T09:32:35+00:00</time>
    </trkpt>
    <trkpt lat="48.086929" lon="16.231966">
    <ele>415.43</ele>
    <time>2009-08-15T09:32:44+00:00</time>
    </trkpt>
    <trkpt lat="48.085563" lon="16.229676">
    <ele>405.33</ele>
    <time>2009-08-15T09:32:52+00:00</time>
    </trkpt>
    <trkpt lat="48.084638" lon="16.226912">
    <ele>394.76</ele>
    <time>2009-08-15T09:33:00+00:00</time>
    </trkpt>
    <trkpt lat="48.083548" lon="16.221725">
    <ele>373.61</ele>
    <time>2009-08-15T09:33:14+00:00</time>
    </trkpt>
    <trkpt lat="48.082351" lon="16.216503">
    <ele>354.86</ele>
    <time>2009-08-15T09:33:29+00:00</time>
    </trkpt>
    <trkpt lat="48.081315" lon="16.214167">
    <ele>348.13</ele>
    <time>2009-08-15T09:33:37+00:00</time>
    </trkpt>
    <trkpt lat="48.079889" lon="16.212253">
    <ele>344.77</ele>
    <time>2009-08-15T09:33:45+00:00</time>
    </trkpt>
    <trkpt lat="48.077618" lon="16.210360">
    <ele>342.85</ele>
    <time>2009-08-15T09:33:56+00:00</time>
    </trkpt>
    <trkpt lat="48.075477" lon="16.208286">
    <ele>345.73</ele>
    <time>2009-08-15T09:34:07+00:00</time>
    </trkpt>
    <trkpt lat="48.073833" lon="16.205687">
    <ele>348.62</ele>
    <time>2009-08-15T09:34:17+00:00</time>
    </trkpt>
    <trkpt lat="48.072719" lon="16.202980">
    <ele>348.13</ele>
    <time>2009-08-15T09:34:26+00:00</time>
    </trkpt>
    <trkpt lat="48.071993" lon="16.199934">
    <ele>344.29</ele>
    <time>2009-08-15T09:34:35+00:00</time>
    </trkpt>
    <trkpt lat="48.071688" lon="16.196557">
    <ele>339.00</ele>
    <time>2009-08-15T09:34:44+00:00</time>
    </trkpt>
    <trkpt lat="48.071799" lon="16.192772">
    <ele>336.60</ele>
    <time>2009-08-15T09:34:54+00:00</time>
    </trkpt>
    <trkpt lat="48.072264" lon="16.189140">
    <ele>339.48</ele>
    <time>2009-08-15T09:35:04+00:00</time>
    </trkpt>
    <trkpt lat="48.072883" lon="16.184608">
    <ele>347.17</ele>
    <time>2009-08-15T09:35:16+00:00</time>
    </trkpt>
    <trkpt lat="48.073549" lon="16.179820">
    <ele>357.27</ele>
    <time>2009-08-15T09:35:29+00:00</time>
    </trkpt>
    <trkpt lat="48.073517" lon="16.176889">
    <ele>361.59</ele>
    <time>2009-08-15T09:35:37+00:00</time>
    </trkpt>
    <trkpt lat="48.072939" lon="16.174113">
    <ele>365.44</ele>
    <time>2009-08-15T09:35:45+00:00</time>
    </trkpt>
    <trkpt lat="48.071876" lon="16.171909">
    <ele>366.88</ele>
    <time>2009-08-15T09:35:52+00:00</time>
    </trkpt>
    <trkpt lat="48.070526" lon="16.170253">
    <ele>366.88</ele>
    <time>2009-08-15T09:35:58+00:00</time>
    </trkpt>
    <trkpt lat="48.068083" lon="16.168282">
    <ele>370.73</ele>
    <time>2009-08-15T09:36:07+00:00</time>
    </trkpt>
    <trkpt lat="48.064571" lon="16.165493">
    <ele>381.30</ele>
    <time>2009-08-15T09:36:21+00:00</time>
    </trkpt>
    <trkpt lat="48.061048" lon="16.162605">
    <ele>394.76</ele>
    <time>2009-08-15T09:36:36+00:00</time>
    </trkpt>
    <trkpt lat="48.059309" lon="16.160284">
    <ele>403.89</ele>
    <time>2009-08-15T09:36:45+00:00</time>
    </trkpt>
    <trkpt lat="48.058199" lon="16.157976">
    <ele>409.18</ele>
    <time>2009-08-15T09:36:52+00:00</time>
    </trkpt>
    <trkpt lat="48.057416" lon="16.155038">
    <ele>413.50</ele>
    <time>2009-08-15T09:36:59+00:00</time>
    </trkpt>
    <trkpt lat="48.057083" lon="16.151865">
    <ele>414.95</ele>
    <time>2009-08-15T09:37:06+00:00</time>
    </trkpt>
    <trkpt lat="48.057283" lon="16.148751">
    <ele>411.10</ele>
    <time>2009-08-15T09:37:13+00:00</time>
    </trkpt>
    <trkpt lat="48.057837" lon="16.146107">
    <ele>405.81</ele>
    <time>2009-08-15T09:37:19+00:00</time>
    </trkpt>
    <trkpt lat="48.059512" lon="16.140897">
    <ele>390.91</ele>
    <time>2009-08-15T09:37:32+00:00</time>
    </trkpt>
    <trkpt lat="48.061661" lon="16.134311">
    <ele>371.69</ele>
    <time>2009-08-15T09:37:48+00:00</time>
    </trkpt>
    <trkpt lat="48.063678" lon="16.128194">
    <ele>356.79</ele>
    <time>2009-08-15T09:38:03+00:00</time>
    </trkpt>
    <trkpt lat="48.064847" lon="16.123806">
    <ele>353.42</ele>
    <time>2009-08-15T09:38:14+00:00</time>
    </trkpt>
    <trkpt lat="48.064927" lon="16.121430">
    <ele>354.38</ele>
    <time>2009-08-15T09:38:20+00:00</time>
    </trkpt>
    <trkpt lat="48.064501" lon="16.118794">
    <ele>356.79</ele>
    <time>2009-08-15T09:38:27+00:00</time>
    </trkpt>
    <trkpt lat="48.063724" lon="16.116772">
    <ele>361.11</ele>
    <time>2009-08-15T09:38:33+00:00</time>
    </trkpt>
    <trkpt lat="48.062450" lon="16.114947">
    <ele>368.32</ele>
    <time>2009-08-15T09:38:40+00:00</time>
    </trkpt>
    <trkpt lat="48.060644" lon="16.113217">
    <ele>377.94</ele>
    <time>2009-08-15T09:38:49+00:00</time>
    </trkpt>
    <trkpt lat="48.058344" lon="16.110693">
    <ele>392.84</ele>
    <time>2009-08-15T09:39:01+00:00</time>
    </trkpt>
    <trkpt lat="48.057201" lon="16.108523">
    <ele>401.01</ele>
    <time>2009-08-15T09:39:08+00:00</time>
    </trkpt>
    <trkpt lat="48.056548" lon="16.105703">
    <ele>406.77</ele>
    <time>2009-08-15T09:39:15+00:00</time>
    </trkpt>
    <trkpt lat="48.056563" lon="16.103162">
    <ele>409.18</ele>
    <time>2009-08-15T09:39:21+00:00</time>
    </trkpt>
    <trkpt lat="48.056951" lon="16.100904">
    <ele>409.18</ele>
    <time>2009-08-15T09:39:27+00:00</time>
    </trkpt>
    <trkpt lat="48.057773" lon="16.098888">
    <ele>407.74</ele>
    <time>2009-08-15T09:39:33+00:00</time>
    </trkpt>
    <trkpt lat="48.059430" lon="16.095968">
    <ele>398.12</ele>
    <time>2009-08-15T09:39:43+00:00</time>
    </trkpt>
    <trkpt lat="48.060539" lon="16.093370">
    <ele>389.95</ele>
    <time>2009-08-15T09:39:51+00:00</time>
    </trkpt>
    <trkpt lat="48.061033" lon="16.090730">
    <ele>383.70</ele>
    <time>2009-08-15T09:39:58+00:00</time>
    </trkpt>
    <trkpt lat="48.061307" lon="16.086157">
    <ele>376.49</ele>
    <time>2009-08-15T09:40:10+00:00</time>
    </trkpt>
    <trkpt lat="48.061487" lon="16.082052">
    <ele>373.61</ele>
    <time>2009-08-15T09:40:21+00:00</time>
    </trkpt>
    <trkpt lat="48.061662" lon="16.078379">
    <ele>371.69</ele>
    <time>2009-08-15T09:40:29+00:00</time>
    </trkpt>
    <trkpt lat="48.062095" lon="16.074869">
    <ele>369.76</ele>
    <time>2009-08-15T09:40:37+00:00</time>
    </trkpt>
    <trkpt lat="48.062974" lon="16.072685">
    <ele>366.40</ele>
    <time>2009-08-15T09:40:43+00:00</time>
    </trkpt>
    <trkpt lat="48.064778" lon="16.069988">
    <ele>358.23</ele>
    <time>2009-08-15T09:40:52+00:00</time>
    </trkpt>
    <trkpt lat="48.066039" lon="16.068744">
    <ele>353.42</ele>
    <time>2009-08-15T09:40:58+00:00</time>
    </trkpt>
    <trkpt lat="48.066976" lon="16.068024">
    <ele>350.54</ele>
    <time>2009-08-15T09:41:04+00:00</time>
    </trkpt>
    <trkpt lat="48.067972" lon="16.067730">
    <ele>348.13</ele>
    <time>2009-08-15T09:41:12+00:00</time>
    </trkpt>
    <trkpt lat="48.068087" lon="16.067668">
    <ele>347.65</ele>
    <time>2009-08-15T09:41:13+00:00</time>
    </trkpt>
    <trkpt lat="48.068188" lon="16.067593">
    <ele>347.17</ele>
    <time>2009-08-15T09:41:14+00:00</time>
    </trkpt>
    <trkpt lat="48.068264" lon="16.067508">
    <ele>346.69</ele>
    <time>2009-08-15T09:41:15+00:00</time>
    </trkpt>
    <trkpt lat="48.068324" lon="16.067440">
    <ele>346.21</ele>
    <time>2009-08-15T09:41:16+00:00</time>
    </trkpt>
    <trkpt lat="48.068366" lon="16.067393">
    <ele>346.21</ele>
    <time>2009-08-15T09:41:17+00:00</time>
    </trkpt>
    <trkpt lat="48.068435" lon="16.067315">
    <ele>344.77</ele>
    <time>2009-08-15T09:41:21+00:00</time>
    </trkpt>
    <trkpt lat="48.068427" lon="16.067098">
    <ele>344.77</ele>
    <time>2009-08-15T09:41:22+00:00</time>
    </trkpt>
    <trkpt lat="48.068427" lon="16.067098">
    <ele>344.29</ele>
    <time>2009-08-15T09:41:23+00:00</time>
    </trkpt>
    <trkpt lat="48.068257" lon="16.066907">
    <ele>344.29</ele>
    <time>2009-08-15T09:41:25+00:00</time>
    </trkpt>
    <trkpt lat="48.068132" lon="16.066576">
    <ele>343.81</ele>
    <time>2009-08-15T09:41:28+00:00</time>
    </trkpt>
    <trkpt lat="48.068105" lon="16.066457">
    <ele>343.81</ele>
    <time>2009-08-15T09:41:29+00:00</time>
    </trkpt>
    <trkpt lat="48.068082" lon="16.066355">
    <ele>343.33</ele>
    <time>2009-08-15T09:41:30+00:00</time>
    </trkpt>
    <trkpt lat="48.068065" lon="16.066275">
    <ele>343.33</ele>
    <time>2009-08-15T09:41:31+00:00</time>
    </trkpt>
    <trkpt lat="48.068057" lon="16.066230">
    <ele>343.33</ele>
    <time>2009-08-15T09:41:32+00:00</time>
    </trkpt>
    <trkpt lat="48.068014" lon="16.065916">
    <ele>343.81</ele>
    <time>2009-08-15T09:41:39+00:00</time>
    </trkpt>
    <trkpt lat="48.068000" lon="16.065807">
    <ele>344.29</ele>
    <time>2009-08-15T09:41:40+00:00</time>
    </trkpt>
    <trkpt lat="48.067984" lon="16.065691">
    <ele>344.29</ele>
    <time>2009-08-15T09:41:41+00:00</time>
    </trkpt>
    <trkpt lat="48.067968" lon="16.065575">
    <ele>344.29</ele>
    <time>2009-08-15T09:41:42+00:00</time>
    </trkpt>
    <trkpt lat="48.067952" lon="16.065456">
    <ele>344.29</ele>
    <time>2009-08-15T09:41:43+00:00</time>
    </trkpt>
    <trkpt lat="48.067580" lon="16.064224">
    <ele>343.81</ele>
    <time>2009-08-15T09:41:54+00:00</time>
    </trkpt>
    <trkpt lat="48.067526" lon="16.064054">
    <ele>343.33</ele>
    <time>2009-08-15T09:42:02+00:00</time>
    </trkpt>
    <trkpt lat="48.067483" lon="16.064000">
    <ele>343.33</ele>
    <time>2009-08-15T09:42:10+00:00</time>
    </trkpt>
    <trkpt lat="48.067450" lon="16.064021">
    <ele>343.33</ele>
    <time>2009-08-15T09:42:11+00:00</time>
    </trkpt>
    <trkpt lat="48.067399" lon="16.064056">
    <ele>343.33</ele>
    <time>2009-08-15T09:42:12+00:00</time>
    </trkpt>
    <trkpt lat="48.067330" lon="16.064102">
    <ele>343.81</ele>
    <time>2009-08-15T09:42:13+00:00</time>
    </trkpt>
    <trkpt lat="48.067247" lon="16.064157">
    <ele>343.81</ele>
    <time>2009-08-15T09:42:14+00:00</time>
    </trkpt>
    <trkpt lat="48.067152" lon="16.064220">
    <ele>343.81</ele>
    <time>2009-08-15T09:42:15+00:00</time>
    </trkpt>
    <trkpt lat="48.066241" lon="16.065088">
    <ele>342.85</ele>
    <time>2009-08-15T09:42:23+00:00</time>
    </trkpt>
    <trkpt lat="48.064419" lon="16.067091">
    <ele>341.41</ele>
    <time>2009-08-15T09:42:36+00:00</time>
    </trkpt>
    <trkpt lat="48.062492" lon="16.069508">
    <ele>339.48</ele>
    <time>2009-08-15T09:42:50+00:00</time>
    </trkpt>
    <trkpt lat="48.061847" lon="16.071078">
    <ele>338.52</ele>
    <time>2009-08-15T09:42:57+00:00</time>
    </trkpt>
    <trkpt lat="48.060965" lon="16.073248">
    <ele>336.12</ele>
    <time>2009-08-15T09:43:07+00:00</time>
    </trkpt>
    <trkpt lat="48.060037" lon="16.074199">
    <ele>334.68</ele>
    <time>2009-08-15T09:43:15+00:00</time>
    </trkpt>
    <trkpt lat="48.058860" lon="16.074501">
    <ele>333.23</ele>
    <time>2009-08-15T09:43:24+00:00</time>
    </trkpt>
    <trkpt lat="48.058351" lon="16.074684">
    <ele>332.75</ele>
    <time>2009-08-15T09:43:28+00:00</time>
    </trkpt>
    <trkpt lat="48.058245" lon="16.074790">
    <ele>332.75</ele>
    <time>2009-08-15T09:43:29+00:00</time>
    </trkpt>
    <trkpt lat="48.058140" lon="16.074895">
    <ele>332.27</ele>
    <time>2009-08-15T09:43:30+00:00</time>
    </trkpt>
    <trkpt lat="48.058058" lon="16.075012">
    <ele>332.27</ele>
    <time>2009-08-15T09:43:31+00:00</time>
    </trkpt>
    <trkpt lat="48.057980" lon="16.075147">
    <ele>332.27</ele>
    <time>2009-08-15T09:43:32+00:00</time>
    </trkpt>
    <trkpt lat="48.057923" lon="16.075280">
    <ele>331.79</ele>
    <time>2009-08-15T09:43:33+00:00</time>
    </trkpt>
    <trkpt lat="48.057891" lon="16.075443">
    <ele>331.31</ele>
    <time>2009-08-15T09:43:34+00:00</time>
    </trkpt>
    <trkpt lat="48.057859" lon="16.075604">
    <ele>331.31</ele>
    <time>2009-08-15T09:43:35+00:00</time>
    </trkpt>
    <trkpt lat="48.057848" lon="16.075752">
    <ele>331.31</ele>
    <time>2009-08-15T09:43:36+00:00</time>
    </trkpt>
    <trkpt lat="48.057857" lon="16.075899">
    <ele>330.83</ele>
    <time>2009-08-15T09:43:37+00:00</time>
    </trkpt>
    <trkpt lat="48.057878" lon="16.076058">
    <ele>330.83</ele>
    <time>2009-08-15T09:43:38+00:00</time>
    </trkpt>
    <trkpt lat="48.057900" lon="16.076223">
    <ele>330.83</ele>
    <time>2009-08-15T09:43:39+00:00</time>
    </trkpt>
    <trkpt lat="48.057923" lon="16.076395">
    <ele>330.83</ele>
    <time>2009-08-15T09:43:40+00:00</time>
    </trkpt>
    <trkpt lat="48.057957" lon="16.076557">
    <ele>330.35</ele>
    <time>2009-08-15T09:43:41+00:00</time>
    </trkpt>
    <trkpt lat="48.058007" lon="16.076730">
    <ele>330.35</ele>
    <time>2009-08-15T09:43:42+00:00</time>
    </trkpt>
    <trkpt lat="48.058385" lon="16.078136">
    <ele>329.87</ele>
    <time>2009-08-15T09:43:52+00:00</time>
    </trkpt>
    <trkpt lat="48.058396" lon="16.078253">
    <ele>329.39</ele>
    <time>2009-08-15T09:43:56+00:00</time>
    </trkpt>
    <trkpt lat="48.058405" lon="16.078363">
    <ele>328.91</ele>
    <time>2009-08-15T09:43:57+00:00</time>
    </trkpt>
    <trkpt lat="48.058405" lon="16.078363">
    <ele>328.91</ele>
    <time>2009-08-15T09:43:58+00:00</time>
    </trkpt>
    <trkpt lat="48.058405" lon="16.078363">
    <ele>328.91</ele>
    <time>2009-08-15T09:43:59+00:00</time>
    </trkpt>
    <trkpt lat="48.058175" lon="16.078363">
    <ele>328.91</ele>
    <time>2009-08-15T09:44:00+00:00</time>
    </trkpt>
    <trkpt lat="48.057871" lon="16.078351">
    <ele>329.87</ele>
    <time>2009-08-15T09:44:04+00:00</time>
    </trkpt>
    <trkpt lat="48.057799" lon="16.078308">
    <ele>329.87</ele>
    <time>2009-08-15T09:44:05+00:00</time>
    </trkpt>
    <trkpt lat="48.057676" lon="16.078234">
    <ele>329.87</ele>
    <time>2009-08-15T09:44:06+00:00</time>
    </trkpt>
    <trkpt lat="48.057648" lon="16.078168">
    <ele>330.35</ele>
    <time>2009-08-15T09:44:07+00:00</time>
    </trkpt>
    <trkpt lat="48.057598" lon="16.078051">
    <ele>330.35</ele>
    <time>2009-08-15T09:44:08+00:00</time>
    </trkpt>
    <trkpt lat="48.057546" lon="16.077928">
    <ele>330.35</ele>
    <time>2009-08-15T09:44:09+00:00</time>
    </trkpt>
    <trkpt lat="48.057512" lon="16.077792">
    <ele>330.35</ele>
    <time>2009-08-15T09:44:10+00:00</time>
    </trkpt>
    <trkpt lat="48.057476" lon="16.077649">
    <ele>329.87</ele>
    <time>2009-08-15T09:44:11+00:00</time>
    </trkpt>
    <trkpt lat="48.057449" lon="16.077501">
    <ele>329.87</ele>
    <time>2009-08-15T09:44:12+00:00</time>
    </trkpt>
    <trkpt lat="48.057425" lon="16.077337">
    <ele>329.87</ele>
    <time>2009-08-15T09:44:13+00:00</time>
    </trkpt>
    <trkpt lat="48.057259" lon="16.075711">
    <ele>328.91</ele>
    <time>2009-08-15T09:44:23+00:00</time>
    </trkpt>
    <trkpt lat="48.057206" lon="16.075580">
    <ele>329.39</ele>
    <time>2009-08-15T09:44:24+00:00</time>
    </trkpt>
    <trkpt lat="48.057146" lon="16.075457">
    <ele>329.39</ele>
    <time>2009-08-15T09:44:25+00:00</time>
    </trkpt>
    <trkpt lat="48.057080" lon="16.075326">
    <ele>329.87</ele>
    <time>2009-08-15T09:44:26+00:00</time>
    </trkpt>
    <trkpt lat="48.057015" lon="16.075196">
    <ele>329.87</ele>
    <time>2009-08-15T09:44:27+00:00</time>
    </trkpt>
    <trkpt lat="48.056932" lon="16.075086">
    <ele>330.35</ele>
    <time>2009-08-15T09:44:28+00:00</time>
    </trkpt>
    <trkpt lat="48.056833" lon="16.074987">
    <ele>330.83</ele>
    <time>2009-08-15T09:44:29+00:00</time>
    </trkpt>
    <trkpt lat="48.055685" lon="16.073644">
    <ele>336.60</ele>
    <time>2009-08-15T09:44:40+00:00</time>
    </trkpt>
    <trkpt lat="48.054395" lon="16.072288">
    <ele>343.81</ele>
    <time>2009-08-15T09:44:52+00:00</time>
    </trkpt>
    <trkpt lat="48.052478" lon="16.071003">
    <ele>352.46</ele>
    <time>2009-08-15T09:45:08+00:00</time>
    </trkpt>
    <trkpt lat="48.051276" lon="16.069938">
    <ele>358.23</ele>
    <time>2009-08-15T09:45:19+00:00</time>
    </trkpt>
    <trkpt lat="48.051214" lon="16.069776">
    <ele>358.71</ele>
    <time>2009-08-15T09:45:20+00:00</time>
    </trkpt>
    <trkpt lat="48.051148" lon="16.069603">
    <ele>359.19</ele>
    <time>2009-08-15T09:45:21+00:00</time>
    </trkpt>
    <trkpt lat="48.050576" lon="16.068047">
    <ele>361.59</ele>
    <time>2009-08-15T09:45:28+00:00</time>
    </trkpt>
    <trkpt lat="48.049215" lon="16.064310">
    <ele>369.28</ele>
    <time>2009-08-15T09:45:43+00:00</time>
    </trkpt>
    <trkpt lat="48.048214" lon="16.061545">
    <ele>376.01</ele>
    <time>2009-08-15T09:45:53+00:00</time>
    </trkpt>
    <trkpt lat="48.047104" lon="16.058178">
    <ele>386.59</ele>
    <time>2009-08-15T09:46:05+00:00</time>
    </trkpt>
    <trkpt lat="48.046579" lon="16.055457">
    <ele>396.68</ele>
    <time>2009-08-15T09:46:15+00:00</time>
    </trkpt>
    <trkpt lat="48.045876" lon="16.053261">
    <ele>403.41</ele>
    <time>2009-08-15T09:46:25+00:00</time>
    </trkpt>
    <trkpt lat="48.045064" lon="16.051600">
    <ele>407.26</ele>
    <time>2009-08-15T09:46:34+00:00</time>
    </trkpt>
    <trkpt lat="48.045003" lon="16.051405">
    <ele>407.74</ele>
    <time>2009-08-15T09:46:35+00:00</time>
    </trkpt>
    <trkpt lat="48.044952" lon="16.051200">
    <ele>407.74</ele>
    <time>2009-08-15T09:46:36+00:00</time>
    </trkpt>
    <trkpt lat="48.044900" lon="16.050992">
    <ele>407.74</ele>
    <time>2009-08-15T09:46:37+00:00</time>
    </trkpt>
    <trkpt lat="48.044901" lon="16.050762">
    <ele>407.74</ele>
    <time>2009-08-15T09:46:38+00:00</time>
    </trkpt>
    <trkpt lat="48.044918" lon="16.050539">
    <ele>407.74</ele>
    <time>2009-08-15T09:46:39+00:00</time>
    </trkpt>
    <trkpt lat="48.044942" lon="16.050321">
    <ele>407.74</ele>
    <time>2009-08-15T09:46:40+00:00</time>
    </trkpt>
    <trkpt lat="48.044987" lon="16.050099">
    <ele>407.74</ele>
    <time>2009-08-15T09:46:41+00:00</time>
    </trkpt>
    <trkpt lat="48.045031" lon="16.049877">
    <ele>407.74</ele>
    <time>2009-08-15T09:46:42+00:00</time>
    </trkpt>
    <trkpt lat="48.045075" lon="16.049658">
    <ele>407.74</ele>
    <time>2009-08-15T09:46:43+00:00</time>
    </trkpt>
    <trkpt lat="48.045159" lon="16.049229">
    <ele>407.74</ele>
    <time>2009-08-15T09:46:45+00:00</time>
    </trkpt>
    <trkpt lat="48.045198" lon="16.049016">
    <ele>407.74</ele>
    <time>2009-08-15T09:46:46+00:00</time>
    </trkpt>
    <trkpt lat="48.045226" lon="16.048793">
    <ele>407.74</ele>
    <time>2009-08-15T09:46:47+00:00</time>
    </trkpt>
    <trkpt lat="48.045204" lon="16.048577">
    <ele>407.74</ele>
    <time>2009-08-15T09:46:48+00:00</time>
    </trkpt>
    <trkpt lat="48.045180" lon="16.048357">
    <ele>407.74</ele>
    <time>2009-08-15T09:46:49+00:00</time>
    </trkpt>
    <trkpt lat="48.045148" lon="16.048129">
    <ele>407.74</ele>
    <time>2009-08-15T09:46:50+00:00</time>
    </trkpt>
    <trkpt lat="48.045114" lon="16.047891">
    <ele>407.26</ele>
    <time>2009-08-15T09:46:51+00:00</time>
    </trkpt>
    <trkpt lat="48.045048" lon="16.047659">
    <ele>407.26</ele>
    <time>2009-08-15T09:46:52+00:00</time>
    </trkpt>
    <trkpt lat="48.044963" lon="16.047425">
    <ele>407.26</ele>
    <time>2009-08-15T09:46:53+00:00</time>
    </trkpt>
    <trkpt lat="48.044086" lon="16.045498">
    <ele>409.66</ele>
    <time>2009-08-15T09:47:01+00:00</time>
    </trkpt>
    <trkpt lat="48.042699" lon="16.043502">
    <ele>421.68</ele>
    <time>2009-08-15T09:47:11+00:00</time>
    </trkpt>
    <trkpt lat="48.041180" lon="16.041802">
    <ele>436.58</ele>
    <time>2009-08-15T09:47:21+00:00</time>
    </trkpt>
    <trkpt lat="48.039756" lon="16.040621">
    <ele>452.92</ele>
    <time>2009-08-15T09:47:30+00:00</time>
    </trkpt>
    <trkpt lat="48.038713" lon="16.038947">
    <ele>465.90</ele>
    <time>2009-08-15T09:47:38+00:00</time>
    </trkpt>
    <trkpt lat="48.037694" lon="16.037647">
    <ele>476.95</ele>
    <time>2009-08-15T09:47:45+00:00</time>
    </trkpt>
    <trkpt lat="48.037590" lon="16.037425">
    <ele>477.91</ele>
    <time>2009-08-15T09:47:46+00:00</time>
    </trkpt>
    <trkpt lat="48.037515" lon="16.037202">
    <ele>479.35</ele>
    <time>2009-08-15T09:47:47+00:00</time>
    </trkpt>
    <trkpt lat="48.037455" lon="16.036962">
    <ele>480.80</ele>
    <time>2009-08-15T09:47:48+00:00</time>
    </trkpt>
    <trkpt lat="48.037396" lon="16.036727">
    <ele>482.24</ele>
    <time>2009-08-15T09:47:49+00:00</time>
    </trkpt>
    <trkpt lat="48.037338" lon="16.036495">
    <ele>483.20</ele>
    <time>2009-08-15T09:47:50+00:00</time>
    </trkpt>
    <trkpt lat="48.036529" lon="16.034662">
    <ele>494.26</ele>
    <time>2009-08-15T09:47:59+00:00</time>
    </trkpt>
    <trkpt lat="48.035260" lon="16.032361">
    <ele>496.18</ele>
    <time>2009-08-15T09:48:11+00:00</time>
    </trkpt>
    <trkpt lat="48.034063" lon="16.030373">
    <ele>491.85</ele>
    <time>2009-08-15T09:48:22+00:00</time>
    </trkpt>
    <trkpt lat="48.032905" lon="16.029245">
    <ele>486.08</ele>
    <time>2009-08-15T09:48:31+00:00</time>
    </trkpt>
    <trkpt lat="48.031616" lon="16.027375">
    <ele>476.47</ele>
    <time>2009-08-15T09:48:43+00:00</time>
    </trkpt>
    <trkpt lat="48.030093" lon="16.025247">
    <ele>463.97</ele>
    <time>2009-08-15T09:48:55+00:00</time>
    </trkpt>
    <trkpt lat="48.029352" lon="16.024332">
    <ele>457.72</ele>
    <time>2009-08-15T09:49:02+00:00</time>
    </trkpt>
    <trkpt lat="48.028853" lon="16.023954">
    <ele>453.88</ele>
    <time>2009-08-15T09:49:10+00:00</time>
    </trkpt>
    <trkpt lat="48.028747" lon="16.023892">
    <ele>452.92</ele>
    <time>2009-08-15T09:49:14+00:00</time>
    </trkpt>
    <trkpt lat="48.028714" lon="16.023872">
    <ele>452.92</ele>
    <time>2009-08-15T09:49:15+00:00</time>
    </trkpt>
    <trkpt lat="48.028679" lon="16.023851">
    <ele>452.44</ele>
    <time>2009-08-15T09:49:16+00:00</time>
    </trkpt>
    <trkpt lat="48.028641" lon="16.023828">
    <ele>452.44</ele>
    <time>2009-08-15T09:49:17+00:00</time>
    </trkpt>
    <trkpt lat="48.028622" lon="16.023817">
    <ele>451.96</ele>
    <time>2009-08-15T09:49:18+00:00</time>
    </trkpt>
    <trkpt lat="48.028622" lon="16.023817">
    <ele>451.96</ele>
    <time>2009-08-15T09:49:19+00:00</time>
    </trkpt>
    <trkpt lat="48.028622" lon="16.023817">
    <ele>451.00</ele>
    <time>2009-08-15T09:49:33+00:00</time>
    </trkpt>
    <trkpt lat="48.028622" lon="16.023817">
    <ele>451.00</ele>
    <time>2009-08-15T09:49:36+00:00</time>
    </trkpt>
    <trkpt lat="48.028609" lon="16.023816">
    <ele>451.00</ele>
    <time>2009-08-15T09:49:37+00:00</time>
    </trkpt>
    <trkpt lat="48.028587" lon="16.023813">
    <ele>451.00</ele>
    <time>2009-08-15T09:49:38+00:00</time>
    </trkpt>
    <trkpt lat="48.028595" lon="16.023654">
    <ele>451.00</ele>
    <time>2009-08-15T09:49:47+00:00</time>
    </trkpt>
    <trkpt lat="48.028512" lon="16.023805">
    <ele>451.00</ele>
    <time>2009-08-15T09:49:49+00:00</time>
    </trkpt>
    <trkpt lat="48.028477" lon="16.023801">
    <ele>451.00</ele>
    <time>2009-08-15T09:49:50+00:00</time>
    </trkpt>
    <trkpt lat="48.028432" lon="16.023796">
    <ele>451.00</ele>
    <time>2009-08-15T09:49:51+00:00</time>
    </trkpt>
    <trkpt lat="48.027950" lon="16.023667">
    <ele>449.55</ele>
    <time>2009-08-15T09:49:57+00:00</time>
    </trkpt>
    <trkpt lat="48.027256" lon="16.023704">
    <ele>447.15</ele>
    <time>2009-08-15T09:50:05+00:00</time>
    </trkpt>
    <trkpt lat="48.027213" lon="16.023716">
    <ele>446.19</ele>
    <time>2009-08-15T09:50:13+00:00</time>
    </trkpt>
    <trkpt lat="48.027122" lon="16.023684">
    <ele>446.19</ele>
    <time>2009-08-15T09:50:16+00:00</time>
    </trkpt>
    <trkpt lat="48.027109" lon="16.023670">
    <ele>446.19</ele>
    <time>2009-08-15T09:50:17+00:00</time>
    </trkpt>
    <trkpt lat="48.027109" lon="16.023670">
    <ele>446.19</ele>
    <time>2009-08-15T09:50:29+00:00</time>
    </trkpt>
    </trkseg>
    </trk>
    <trk>
    <name>ACTIVE LOG: 15 Aug 2009 11:50</name>
    <trkseg>
    <trkpt lat="48.027109" lon="16.023670">
    <ele>446.19</ele>
    <time>2009-08-15T09:50:36+00:00</time>
    </trkpt>
    <trkpt lat="48.026863" lon="16.023388">
    <ele>446.19</ele>
    <time>2009-08-15T09:50:43+00:00</time>
    </trkpt>
    <trkpt lat="48.026863" lon="16.023388">
    <ele>446.67</ele>
    <time>2009-08-15T09:50:44+00:00</time>
    </trkpt>
    <trkpt lat="48.026863" lon="16.023388">
    <ele>446.67</ele>
    <time>2009-08-15T09:50:45+00:00</time>
    </trkpt>
    <trkpt lat="48.027134" lon="16.023698">
    <ele>446.67</ele>
    <time>2009-08-15T09:50:51+00:00</time>
    </trkpt>
    <trkpt lat="48.027123" lon="16.023772">
    <ele>446.67</ele>
    <time>2009-08-15T09:50:52+00:00</time>
    </trkpt>
    <trkpt lat="48.027091" lon="16.023803">
    <ele>446.67</ele>
    <time>2009-08-15T09:50:53+00:00</time>
    </trkpt>
    <trkpt lat="48.026643" lon="16.024378">
    <ele>446.19</ele>
    <time>2009-08-15T09:51:00+00:00</time>
    </trkpt>
    <trkpt lat="48.026112" lon="16.025121">
    <ele>444.27</ele>
    <time>2009-08-15T09:51:06+00:00</time>
    </trkpt>
    <trkpt lat="48.026007" lon="16.025199">
    <ele>443.79</ele>
    <time>2009-08-15T09:51:07+00:00</time>
    </trkpt>
    <trkpt lat="48.025900" lon="16.025258">
    <ele>443.79</ele>
    <time>2009-08-15T09:51:08+00:00</time>
    </trkpt>
    <trkpt lat="48.025787" lon="16.025303">
    <ele>443.31</ele>
    <time>2009-08-15T09:51:09+00:00</time>
    </trkpt>
    <trkpt lat="48.025672" lon="16.025349">
    <ele>443.31</ele>
    <time>2009-08-15T09:51:10+00:00</time>
    </trkpt>
    <trkpt lat="48.025557" lon="16.025395">
    <ele>442.82</ele>
    <time>2009-08-15T09:51:11+00:00</time>
    </trkpt>
    <trkpt lat="48.025441" lon="16.025442">
    <ele>442.82</ele>
    <time>2009-08-15T09:51:12+00:00</time>
    </trkpt>
    <trkpt lat="48.025103" lon="16.025577">
    <ele>441.86</ele>
    <time>2009-08-15T09:51:15+00:00</time>
    </trkpt>
    <trkpt lat="48.025005" lon="16.025651">
    <ele>441.38</ele>
    <time>2009-08-15T09:51:16+00:00</time>
    </trkpt>
    <trkpt lat="48.024920" lon="16.025724">
    <ele>441.38</ele>
    <time>2009-08-15T09:51:17+00:00</time>
    </trkpt>
    <trkpt lat="48.024844" lon="16.025846">
    <ele>440.90</ele>
    <time>2009-08-15T09:51:18+00:00</time>
    </trkpt>
    <trkpt lat="48.024765" lon="16.025972">
    <ele>440.90</ele>
    <time>2009-08-15T09:51:19+00:00</time>
    </trkpt>
    <trkpt lat="48.024684" lon="16.026101">
    <ele>440.90</ele>
    <time>2009-08-15T09:51:20+00:00</time>
    </trkpt>
    <trkpt lat="48.023583" lon="16.028085">
    <ele>438.50</ele>
    <time>2009-08-15T09:51:33+00:00</time>
    </trkpt>
    <trkpt lat="48.023100" lon="16.029049">
    <ele>437.54</ele>
    <time>2009-08-15T09:51:39+00:00</time>
    </trkpt>
    <trkpt lat="48.023005" lon="16.029176">
    <ele>437.06</ele>
    <time>2009-08-15T09:51:40+00:00</time>
    </trkpt>
    <trkpt lat="48.022890" lon="16.029245">
    <ele>437.06</ele>
    <time>2009-08-15T09:51:41+00:00</time>
    </trkpt>
    <trkpt lat="48.022766" lon="16.029316">
    <ele>437.06</ele>
    <time>2009-08-15T09:51:42+00:00</time>
    </trkpt>
    <trkpt lat="48.022639" lon="16.029364">
    <ele>436.58</ele>
    <time>2009-08-15T09:51:43+00:00</time>
    </trkpt>
    <trkpt lat="48.022492" lon="16.029391">
    <ele>436.58</ele>
    <time>2009-08-15T09:51:44+00:00</time>
    </trkpt>
    <trkpt lat="48.022335" lon="16.029420">
    <ele>436.58</ele>
    <time>2009-08-15T09:51:45+00:00</time>
    </trkpt>
    <trkpt lat="48.020758" lon="16.029506">
    <ele>442.34</ele>
    <time>2009-08-15T09:51:55+00:00</time>
    </trkpt>
    <trkpt lat="48.020248" lon="16.029553">
    <ele>446.19</ele>
    <time>2009-08-15T09:52:00+00:00</time>
    </trkpt>
    <trkpt lat="48.019897" lon="16.029457">
    <ele>449.07</ele>
    <time>2009-08-15T09:52:04+00:00</time>
    </trkpt>
    <trkpt lat="48.019788" lon="16.029418">
    <ele>449.07</ele>
    <time>2009-08-15T09:52:05+00:00</time>
    </trkpt>
    <trkpt lat="48.018366" lon="16.029027">
    <ele>441.86</ele>
    <time>2009-08-15T09:52:17+00:00</time>
    </trkpt>
    <trkpt lat="48.017307" lon="16.029085">
    <ele>434.65</ele>
    <time>2009-08-15T09:52:24+00:00</time>
    </trkpt>
    <trkpt lat="48.015605" lon="16.029367">
    <ele>426.48</ele>
    <time>2009-08-15T09:52:35+00:00</time>
    </trkpt>
    <trkpt lat="48.014932" lon="16.029525">
    <ele>421.68</ele>
    <time>2009-08-15T09:52:44+00:00</time>
    </trkpt>
    <trkpt lat="48.013607" lon="16.030675">
    <ele>417.83</ele>
    <time>2009-08-15T09:52:53+00:00</time>
    </trkpt>
    </trkseg>
    </trk>
    <trk>
    <name>ACTIVE LOG: 15 Aug 2009 11:52</name>
    <trkseg>
    <trkpt lat="48.013287" lon="16.031035">
    <ele>416.39</ele>
    <time>2009-08-15T09:52:56+00:00</time>
    </trkpt>
    <trkpt lat="48.012141" lon="16.032376">
    <ele>413.02</ele>
    <time>2009-08-15T09:53:07+00:00</time>
    </trkpt>
    <trkpt lat="48.011027" lon="16.033645">
    <ele>411.10</ele>
    <time>2009-08-15T09:53:18+00:00</time>
    </trkpt>
    <trkpt lat="48.010544" lon="16.034435">
    <ele>410.62</ele>
    <time>2009-08-15T09:53:26+00:00</time>
    </trkpt>
    <trkpt lat="48.010315" lon="16.034786">
    <ele>410.62</ele>
    <time>2009-08-15T09:53:34+00:00</time>
    </trkpt>
    <trkpt lat="48.009529" lon="16.035287">
    <ele>410.14</ele>
    <time>2009-08-15T09:53:43+00:00</time>
    </trkpt>
    <trkpt lat="48.008440" lon="16.035261">
    <ele>408.70</ele>
    <time>2009-08-15T09:53:52+00:00</time>
    </trkpt>
    <trkpt lat="48.007630" lon="16.035166">
    <ele>407.26</ele>
    <time>2009-08-15T09:53:59+00:00</time>
    </trkpt>
    <trkpt lat="48.007529" lon="16.035203">
    <ele>407.26</ele>
    <time>2009-08-15T09:54:00+00:00</time>
    </trkpt>
    <trkpt lat="48.007434" lon="16.035239">
    <ele>406.77</ele>
    <time>2009-08-15T09:54:01+00:00</time>
    </trkpt>
    <trkpt lat="48.007347" lon="16.035272">
    <ele>406.29</ele>
    <time>2009-08-15T09:54:02+00:00</time>
    </trkpt>
    <trkpt lat="48.007272" lon="16.035329">
    <ele>406.29</ele>
    <time>2009-08-15T09:54:03+00:00</time>
    </trkpt>
    <trkpt lat="48.007211" lon="16.035380">
    <ele>405.81</ele>
    <time>2009-08-15T09:54:04+00:00</time>
    </trkpt>
    <trkpt lat="48.006960" lon="16.035589">
    <ele>403.41</ele>
    <time>2009-08-15T09:54:12+00:00</time>
    </trkpt>
    <trkpt lat="48.006814" lon="16.035709">
    <ele>402.45</ele>
    <time>2009-08-15T09:54:21+00:00</time>
    </trkpt>
    <trkpt lat="48.006779" lon="16.035730">
    <ele>401.97</ele>
    <time>2009-08-15T09:54:22+00:00</time>
    </trkpt>
    <trkpt lat="48.006526" lon="16.035882">
    <ele>401.49</ele>
    <time>2009-08-15T09:54:29+00:00</time>
    </trkpt>
    <trkpt lat="48.006509" lon="16.035892">
    <ele>400.05</ele>
    <time>2009-08-15T09:54:41+00:00</time>
    </trkpt>
    </trkseg>
    </trk>
    <wpt lat="48.023563" lon="16.034138">
    <ele>407.72</ele>
    <name>Mostheuriger</name>
    <sym>Waypoint</sym>
    </wpt>
    <wpt lat="48.014933" lon="16.029525">
    <ele>-0.11</ele>
    <name>Parkplatz</name>
    <sym>Parking Area</sym>
    <extensions>Altenmarkt an der TriestingBaden2565</extensions>
    </wpt>
    <wpt lat="48.191917" lon="16.349984">
    <ele>151.29</ele>
    <name>ZU HAUSE</name>
    <sym>Residence</sym>
    <extensions>Marchettigasse 5Wien - 6. Bezirk-MariahilfWien1060</extensions>
    </wpt>
	<wpt lat="48.006468" lon="16.036000">
	<ele>400.51</ele>
	<name>OUTSIDE_WP: Parkplatz Thalhofergrat</name>
	</wpt>
    </gpx>
    
END_HERE


my $gpx = Geo::Gpx->new( xml => $gpx_test_file);

print {*STDERR} "Dump of \$gpx:\n" . Dumper($gpx) . "\n" if $DEBUG > 1;

my $wp = $gpx->waypoints();

my $all_tracks = $gpx->tracks();

my ($first_second, $last_second) = first_and_last_second_of('2009-08-15');

my $selected_tracks = filter_trk($all_tracks, $first_second, $last_second);

# create a new gpx-object and fill it with the selcted tracks
my $new_gpx = Geo::Gpx->new();
$new_gpx->tracks( $selected_tracks );

my $bounds = $new_gpx->bounds();            # calculate the boundin-box of the selected tracks
my $all_wp = $gpx->waypoints();              # export all waypoints from the original GPX-file
my $tolerance = 0.0002;
my $sel_wp = filter_wp($all_wp, $bounds, $tolerance);   # export all waypoints within this box + tolerance
my $wp_data = Dumper($sel_wp);
say {*STDERR} ($wp_data) if $DEBUG > 1;

like($wp_data, qr/OUTSIDE_WP: Parkplatz Thalhofergrat/, 'Waypoint at the end of the track (slightly outside of the boinding-box) included');

# ===============
# = Helper Subs =
# ===============
sub say { print @_, "\n" };