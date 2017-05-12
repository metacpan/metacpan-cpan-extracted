/*
 * Lingua::StanfordCoreNLP
 * Copyright © 2011-2013 Kalle Räisänen.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 * 
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see L<http://www.gnu.org/licenses/>.
 */
package be.fivebyfive.lingua.stanfordcorenlp;

import java.io.PipedInputStream;
import java.io.PipedOutputStream;
import java.io.PrintStream;
import java.io.IOException;
import java.util.Properties;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;


import edu.stanford.nlp.dcoref.CorefChain;
import edu.stanford.nlp.dcoref.CorefChain.CorefMention;
import edu.stanford.nlp.dcoref.CorefCoreAnnotations.CorefChainAnnotation;

import edu.stanford.nlp.ling.CoreLabel;

import edu.stanford.nlp.ling.CoreAnnotations.LemmaAnnotation;
import edu.stanford.nlp.ling.CoreAnnotations.NamedEntityTagAnnotation;
import edu.stanford.nlp.ling.CoreAnnotations.PartOfSpeechAnnotation;
import edu.stanford.nlp.ling.CoreAnnotations.SentencesAnnotation;
import edu.stanford.nlp.ling.CoreAnnotations.TextAnnotation;
import edu.stanford.nlp.ling.CoreAnnotations.TokensAnnotation;

import edu.stanford.nlp.pipeline.*;

import edu.stanford.nlp.trees.GrammaticalRelation;
import edu.stanford.nlp.trees.semgraph.SemanticGraph;
import edu.stanford.nlp.trees.semgraph.SemanticGraphEdge;
import edu.stanford.nlp.trees.semgraph.SemanticGraphCoreAnnotations.CollapsedCCProcessedDependenciesAnnotation;

import edu.stanford.nlp.util.CoreMap;


public class Pipeline {
    private StanfordCoreNLP   pipeline = null;
    private boolean           bidirectionalCorefs = false;
    private Properties        props = null;

    public StanfordCoreNLP getPipeline() {
         return pipeline;
    }

    public Pipeline() {
         this(false);
    }

    public Pipeline(boolean bidirectionalCorefs) {
         this(bidirectionalCorefs, new Properties());
    }
    
    public Pipeline(boolean bidirectionalCorefs, Properties props) {
       this.bidirectionalCorefs = bidirectionalCorefs;
       this.props = props;
       if (this.props.isEmpty()) {
          props.put("annotators", "tokenize, ssplit, pos, lemma, ner, parse, dcoref");
       }
    }

    public Properties getProperties() {
       return props;
    }

    public void setProperties(Properties props) {
        this.props = props;
    }

    public void initPipeline() {
        pipeline = new StanfordCoreNLP(props, false);
    }

    public PipelineSentenceList process(String text) {
        if(pipeline == null)
            initPipeline();

        PipelineSentenceList outList  = new PipelineSentenceList();
        Annotation           document = new Annotation(text);

        if(document == null)
            return null;

        pipeline.annotate(document);

        for(CoreMap sentence: document.get(SentencesAnnotation.class)) {
            String                  str = sentence.get(TextAnnotation.class);
            PipelineTokenList       ptl = new PipelineTokenList();
            PipelineDependencyList  pel = new PipelineDependencyList();

            for(CoreLabel token: sentence.get(TokensAnnotation.class)) {
                String word = token.get(TextAnnotation.class);
                String pos  = token.get(PartOfSpeechAnnotation.class);
                String ner  = token.get(NamedEntityTagAnnotation.class);
                String lemma= token.get(LemmaAnnotation.class);

                ptl.add(new PipelineToken(word, pos, ner, lemma));
            }

            SemanticGraph dependencies = sentence.get(CollapsedCCProcessedDependenciesAnnotation.class);

            if(dependencies != null) {
                for(SemanticGraphEdge edge: dependencies.edgeListSorted()) {
                    GrammaticalRelation rel = edge.getRelation();

                    int govTokenIndex = edge.getGovernor().index()  - 1;
                    int depTokenIndex = edge.getDependent().index() - 1;

                    if(govTokenIndex >= 0 && depTokenIndex >= 0 &&
                       govTokenIndex < ptl.size() && depTokenIndex < ptl.size()
                    ) {
                        pel.add(new PipelineDependency(
                                ptl.get(govTokenIndex),
                                ptl.get(depTokenIndex),
                                govTokenIndex,
                                depTokenIndex,
                                rel
                        ));
                    } else {
                        System.err.println("Index of " + edge.toString() + " out of range!");
                    }
                }
            }
            outList.add(new PipelineSentence(str, ptl, pel));
        }//for -- SentenceAnnotation
        Map<Integer, CorefChain> graph = document.get(CorefChainAnnotation.class);


        if(graph != null) {
            for(CorefChain crc: graph.values()) {
                List<CorefMention> crms = crc.getMentionsInTextualOrder();
                ArrayList<int[]> corefs = new ArrayList<int[]>();

                for(CorefMention crm: crms) {
                    corefs.add(new int[]{crm.sentNum, crm.headIndex});
                }

                if(corefs.size() > 1) {
                    int fromSentence = (corefs.get(0))[0] - 1;
                    int fromHead     = (corefs.get(0))[1] - 1;
                    int toSentence   = (corefs.get(1))[0] - 1;
                    int toHead       = (corefs.get(1))[1] - 1;

                    if(fromSentence >= 0 && toSentence >= 0 &&
                       fromHead >= 0 && toHead >= 0 &&
                       fromSentence < outList.size() && toSentence < outList.size() &&
                       fromHead < outList.get(fromSentence).getTokens().size() &&
                       toHead   < outList.get(toSentence).getTokens().size()
                    ) {
                        outList.get(fromSentence).addCoreference(
                            new PipelineCoreference(
                                fromSentence, toSentence, fromHead, toHead,
                                outList.get(fromSentence).getTokens().get(fromHead),
                                outList.get(toSentence).getTokens().get(toHead)
                            )
                        );
                        if(bidirectionalCorefs && toSentence != fromSentence) {
                            outList.get(toSentence).addCoreference(
                                new PipelineCoreference(
                                    toSentence, fromSentence, toHead, fromHead,
                                    outList.get(toSentence).getTokens().get(toHead),
                                    outList.get(fromSentence).getTokens().get(fromHead)
                                )
                            );
                        }
                    }//if(fromSentence
                }//if(corefs
            }//for
        }//if(graph

        return outList;
    }//process
}

